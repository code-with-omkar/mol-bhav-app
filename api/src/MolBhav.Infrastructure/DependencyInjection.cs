using System.Text;
using Dapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Infrastructure.Authentication;
using MolBhav.Infrastructure.Messaging;
using MolBhav.Infrastructure.Messaging.Outbox;
using MolBhav.Infrastructure.Notifications;
using MolBhav.Infrastructure.Persistence;
using MolBhav.Infrastructure.Persistence.Interceptors;
using MolBhav.Infrastructure.Persistence.Read;
using MolBhav.Infrastructure.Persistence.Read.Catalog;
using MolBhav.Infrastructure.Persistence.Read.Identity;
using MolBhav.Infrastructure.Persistence.Repositories.Catalog;
using MolBhav.Infrastructure.Persistence.Repositories.Identity;
using Npgsql;

namespace MolBhav.Infrastructure;

public static class DependencyInjection
{
    /// <summary>Health-check tag for dependencies that must be up before the instance receives traffic.</summary>
    public const string ReadinessTag = "ready";

    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        ArgumentNullException.ThrowIfNull(configuration);
        ArgumentNullException.ThrowIfNull(environment);

        services.TryAddSingleton(TimeProvider.System);

        services
            .AddPersistence(configuration)
            .AddOutbox(configuration)
            .AddJwtAuthentication(configuration)
            .AddIdentityModule(configuration, environment)
            .AddCatalogModule();

        return services;
    }

    private static IServiceCollection AddCatalogModule(this IServiceCollection services)
    {
        services.AddScoped<IProcurementCategoryRepository, ProcurementCategoryRepository>();
        services.AddScoped<IProductRepository, ProductRepository>();
        services.AddScoped<IUnitOfMeasureRepository, UnitOfMeasureRepository>();
        services.AddScoped<ICatalogReadService, CatalogReadService>();
        services.AddScoped<IProcurementCategoryLookup, ProcurementCategoryLookup>();

        return services;
    }

    private static IServiceCollection AddIdentityModule(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IOtpChallengeRepository, OtpChallengeRepository>();
        services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
        services.AddScoped<IUserProfileReadService, UserProfileReadService>();

        services.AddSingleton<IOtpCodeGenerator, OtpCodeGenerator>();

        var otpDelivery = configuration.GetSection(OtpDeliveryOptions.SectionName).Get<OtpDeliveryOptions>() ?? new OtpDeliveryOptions();

        switch (otpDelivery.Provider)
        {
            // Fail closed: the log sender prints live codes, so it must never be reachable outside a developer machine.
            case OtpDeliveryProviders.Log when environment.IsDevelopment():
                services.AddSingleton<IOtpSender, LoggingOtpSender>();
                break;

            case OtpDeliveryProviders.Log:
                throw new InvalidOperationException(
                    $"{OtpDeliveryOptions.SectionName}:Provider '{OtpDeliveryProviders.Log}' writes OTP codes to the log and is allowed only in " +
                    $"Development (current environment: '{environment.EnvironmentName}'). Configure a real SMS/WhatsApp provider.");

            default:
                throw new InvalidOperationException(
                    $"Unknown {OtpDeliveryOptions.SectionName}:Provider '{otpDelivery.Provider}'.");
        }

        return services;
    }

    private static IServiceCollection AddPersistence(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<DatabaseOptions>()
            .Bind(configuration.GetSection(DatabaseOptions.SectionName))
            .Validate(o => o.MaxRetryCount is >= 0 and <= 10, "Database:MaxRetryCount must be between 0 and 10.")
            .Validate(o => o.CommandTimeoutSeconds is > 0 and <= 300, "Database:CommandTimeoutSeconds must be between 1 and 300.")
            .ValidateOnStart();

        var connectionString = configuration.GetConnectionString(DatabaseOptions.ConnectionStringName);
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                $"Connection string '{DatabaseOptions.ConnectionStringName}' is not configured. " +
                $"Set it with 'dotnet user-secrets set \"ConnectionStrings:{DatabaseOptions.ConnectionStringName}\" \"...\"' " +
                $"or the 'ConnectionStrings__{DatabaseOptions.ConnectionStringName}' environment variable.");
        }

        // One pooled data source shared by EF Core (writes) and Dapper (reads).
        services.AddNpgsqlDataSource(connectionString);

        services.AddScoped<SoftDeleteInterceptor>();
        services.AddScoped<AuditableEntityInterceptor>();
        services.AddScoped<DomainEventsToOutboxInterceptor>();

        services.AddDbContext<MolBhavDbContext>((serviceProvider, options) =>
        {
            var database = serviceProvider.GetRequiredService<IOptions<DatabaseOptions>>().Value;

            options.UseNpgsql(serviceProvider.GetRequiredService<NpgsqlDataSource>(), npgsql =>
            {
                npgsql.MigrationsAssembly(typeof(MolBhavDbContext).Assembly.GetName().Name);
                npgsql.MigrationsHistoryTable("__ef_migrations_history", Schemas.Platform);
                npgsql.EnableRetryOnFailure(database.MaxRetryCount);
                npgsql.CommandTimeout(database.CommandTimeoutSeconds);
            });

            // Order matters: soft-delete converts deletes to updates before auditing stamps them.
            options.AddInterceptors(
                serviceProvider.GetRequiredService<SoftDeleteInterceptor>(),
                serviceProvider.GetRequiredService<AuditableEntityInterceptor>(),
                serviceProvider.GetRequiredService<DomainEventsToOutboxInterceptor>());

            if (database.EnableSensitiveDataLogging)
            {
                options.EnableSensitiveDataLogging();
            }

            if (database.EnableDetailedErrors)
            {
                options.EnableDetailedErrors();
            }
        });

        services.AddScoped<IUnitOfWork>(serviceProvider => serviceProvider.GetRequiredService<MolBhavDbContext>());

        // Dapper: map snake_case columns onto PascalCase read models without per-query aliases.
        DefaultTypeMap.MatchNamesWithUnderscores = true;
        services.AddSingleton<IDbConnectionFactory, NpgsqlConnectionFactory>();

        services.AddHealthChecks()
            .AddDbContextCheck<MolBhavDbContext>("postgresql", tags: [ReadinessTag]);

        return services;
    }

    private static IServiceCollection AddOutbox(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<OutboxOptions>()
            .Bind(configuration.GetSection(OutboxOptions.SectionName))
            .Validate(o => o.PollingIntervalSeconds is >= 1 and <= 300, "Outbox:PollingIntervalSeconds must be between 1 and 300.")
            .Validate(o => o.BatchSize is >= 1 and <= 1000, "Outbox:BatchSize must be between 1 and 1000.")
            .Validate(o => o.MaxAttempts is >= 1 and <= 50, "Outbox:MaxAttempts must be between 1 and 50.")
            .ValidateOnStart();

        services.AddScoped<DomainEventDispatcher>();
        services.AddHostedService<OutboxProcessor>();

        return services;
    }

    private static IServiceCollection AddJwtAuthentication(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<JwtOptions>()
            .Bind(configuration.GetSection(JwtOptions.SectionName))
            .Validate(o => !string.IsNullOrWhiteSpace(o.Issuer) && !string.IsNullOrWhiteSpace(o.Audience), "Jwt:Issuer and Jwt:Audience are required.")
            .Validate(
                o => Encoding.UTF8.GetByteCount(o.SigningKey ?? string.Empty) >= JwtOptions.MinimumSigningKeyBytes,
                $"Jwt:SigningKey must be at least {JwtOptions.MinimumSigningKeyBytes} bytes. Supply it via user-secrets or environment, never appsettings.")
            .Validate(o => o.AccessTokenLifetimeMinutes is >= 1 and <= 60, "Jwt:AccessTokenLifetimeMinutes must be between 1 and 60.")
            .Validate(o => o.RefreshTokenLifetimeDays is >= 1 and <= 90, "Jwt:RefreshTokenLifetimeDays must be between 1 and 90.")
            .Validate(o => o.ClockSkewSeconds is >= 0 and <= 300, "Jwt:ClockSkewSeconds must be between 0 and 300.")
            .ValidateOnStart();

        services.AddSingleton<IJwtTokenService, JwtTokenService>();

        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer();

        // Configure the bearer handler from the validated options instead of reading raw configuration twice.
        services.AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
            .Configure<IOptions<JwtOptions>>((bearer, jwtOptions) =>
            {
                var jwt = jwtOptions.Value;

                bearer.MapInboundClaims = false;
                bearer.RequireHttpsMetadata = true;
                bearer.SaveToken = false;
                bearer.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = jwt.Issuer,
                    ValidateAudience = true,
                    ValidAudience = jwt.Audience,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = JwtSigningKey.Create(jwt.SigningKey),
                    ValidAlgorithms = [JwtSigningKey.Algorithm],
                    ValidateLifetime = true,
                    RequireExpirationTime = true,
                    RequireSignedTokens = true,
                    ClockSkew = TimeSpan.FromSeconds(jwt.ClockSkewSeconds),
                    NameClaimType = MolBhavClaimTypes.Subject,
                    RoleClaimType = MolBhavClaimTypes.Role,
                };
            });

        return services;
    }
}
