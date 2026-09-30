using System.Net.Http.Headers;
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
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Application.Abstractions.Watchlist;
using MolBhav.Infrastructure.Authentication;
using MolBhav.Infrastructure.Billing;
using MolBhav.Infrastructure.Billing.Razorpay;
using MolBhav.Infrastructure.Ingestion;
using MolBhav.Infrastructure.Messaging;
using MolBhav.Infrastructure.Messaging.Outbox;
using MolBhav.Infrastructure.Notifications;
using MolBhav.Infrastructure.Persistence;
using MolBhav.Infrastructure.Persistence.Interceptors;
using MolBhav.Infrastructure.Persistence.Read;
using MolBhav.Infrastructure.Persistence.Read.Alerting;
using MolBhav.Infrastructure.Persistence.Read.Billing;
using MolBhav.Infrastructure.Persistence.Read.Catalog;
using MolBhav.Infrastructure.Persistence.Read.Identity;
using MolBhav.Infrastructure.Persistence.Read.Ingestion;
using MolBhav.Infrastructure.Persistence.Read.Localization;
using MolBhav.Infrastructure.Persistence.Read.Market;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using MolBhav.Infrastructure.Persistence.Read.Notification;
using MolBhav.Infrastructure.Persistence.Read.Pricing;
using MolBhav.Infrastructure.Persistence.Read.Procurement;
using MolBhav.Infrastructure.Persistence.Read.Reporting;
using MolBhav.Infrastructure.Persistence.Read.Support;
using MolBhav.Infrastructure.Persistence.Read.Watchlist;
using MolBhav.Infrastructure.Persistence.Repositories.Alerting;
using MolBhav.Infrastructure.Persistence.Repositories.Billing;
using MolBhav.Infrastructure.Persistence.Repositories.Catalog;
using MolBhav.Infrastructure.Persistence.Repositories.Identity;
using MolBhav.Infrastructure.Persistence.Repositories.Ingestion;
using MolBhav.Infrastructure.Persistence.Repositories.Localization;
using MolBhav.Infrastructure.Persistence.Repositories.Market;
using MolBhav.Infrastructure.Persistence.Repositories.Notification;
using MolBhav.Infrastructure.Persistence.Repositories.Pricing;
using MolBhav.Infrastructure.Persistence.Repositories.Procurement;
using MolBhav.Infrastructure.Persistence.Repositories.Reporting;
using MolBhav.Infrastructure.Persistence.Repositories.Support;
using MolBhav.Infrastructure.Persistence.Repositories.Watchlist;
using MolBhav.Infrastructure.Reporting;
using MolBhav.Infrastructure.Support;
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
            .AddCatalogModule()
            .AddMarketModule()
            .AddPricingModule()
            .AddWatchlistModule()
            .AddAlertingModule()
            .AddProcurementModule()
            .AddNotificationModule(configuration, environment)
            .AddReportingModule()
            .AddBillingModule(configuration, environment)
            .AddIngestionModule(configuration, environment)
            .AddLocalizationModule()
            .AddSupportModule(configuration);

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

    private static IServiceCollection AddMarketModule(this IServiceCollection services)
    {
        services.AddScoped<IStateRepository, StateRepository>();
        services.AddScoped<IMandiRepository, MandiRepository>();
        services.AddScoped<ISupplierRepository, SupplierRepository>();
        services.AddScoped<IMarketReadService, MarketReadService>();

        return services;
    }

    private static IServiceCollection AddPricingModule(this IServiceCollection services)
    {
        services.AddScoped<IPriceSourceRepository, PriceSourceRepository>();
        services.AddScoped<IPriceRecordRepository, PriceRecordRepository>();
        services.AddScoped<IPricingReadService, PricingReadService>();

        return services;
    }

    private static IServiceCollection AddWatchlistModule(this IServiceCollection services)
    {
        services.AddScoped<IWatchlistItemRepository, WatchlistItemRepository>();
        services.AddScoped<IWatchlistReadService, WatchlistReadService>();

        return services;
    }

    private static IServiceCollection AddAlertingModule(this IServiceCollection services)
    {
        services.AddScoped<IAlertRuleRepository, AlertRuleRepository>();
        services.AddScoped<IAlertRepository, AlertRepository>();
        services.AddScoped<IAlertingReadService, AlertingReadService>();

        return services;
    }

    private static IServiceCollection AddProcurementModule(this IServiceCollection services)
    {
        services.AddScoped<IProcurementRequirementRepository, ProcurementRequirementRepository>();
        services.AddScoped<IProcurementOpportunityRepository, ProcurementOpportunityRepository>();
        services.AddScoped<ICostComponentRepository, CostComponentRepository>();
        services.AddScoped<IProcurementReadService, ProcurementReadService>();

        return services;
    }

    private static IServiceCollection AddNotificationModule(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<INotificationReadService, NotificationReadService>();
        services.AddScoped<IDeviceTokenRepository, DeviceTokenRepository>();
        services.AddScoped<INotificationPreferencesRepository, NotificationPreferencesRepository>();

        var fcm = configuration.GetSection(FcmCredentialOptions.SectionName).Get<FcmCredentialOptions>() ?? new FcmCredentialOptions();
        var wa = configuration.GetSection(WhatsAppOptions.SectionName).Get<WhatsAppOptions>() ?? new WhatsAppOptions();

        var hasFcm = !string.IsNullOrWhiteSpace(fcm.ServiceAccountJson);
        var hasWhatsApp = !string.IsNullOrWhiteSpace(wa.AccessToken) && !string.IsNullOrWhiteSpace(wa.PhoneNumberId);

        if (!environment.IsDevelopment() && (!hasFcm || !hasWhatsApp))
        {
            throw new InvalidOperationException(
                "Push notification credentials are required in non-Development environments. " +
                $"Supply '{FcmCredentialOptions.SectionName}:ServiceAccountJson' and '{WhatsAppOptions.SectionName}:AccessToken' / 'PhoneNumberId' " +
                "via user-secrets or environment variables.");
        }

        if (hasFcm && hasWhatsApp)
        {
            // Real FCM + WhatsApp senders.
            services.Configure<FcmCredentialOptions>(configuration.GetSection(FcmCredentialOptions.SectionName));
            services.Configure<WhatsAppOptions>(configuration.GetSection(WhatsAppOptions.SectionName));

            services.AddSingleton<FirebaseMessaging>(_ =>
            {
                var credential = GoogleCredential.FromJson(fcm.ServiceAccountJson);
                var app = FirebaseApp.Create(new AppOptions { Credential = credential });
                return FirebaseMessaging.GetMessaging(app);
            });

            services.AddHttpClient(WhatsAppCloudSender.HttpClientName, (sp, client) =>
            {
                client.BaseAddress = new Uri("https://graph.facebook.com/v19.0/");
                var token = sp.GetRequiredService<IOptions<WhatsAppOptions>>().Value.AccessToken;
                client.DefaultRequestHeaders.Authorization =
                    new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
            });

            services.AddScoped<FcmPushSender>();
            services.AddScoped<WhatsAppCloudSender>();
            services.AddScoped<INotificationSender, CompositeNotificationSender>();
        }
        else
        {
            // Dev fallback: neither key is configured — log only.
            services.AddScoped<INotificationSender, LoggingNotificationSender>();
        }

        return services;
    }

    private static IServiceCollection AddReportingModule(this IServiceCollection services)
    {
        services.AddScoped<IReportRepository, ReportRepository>();
        services.AddScoped<IReportReadService, ReportReadService>();
        services.AddScoped<IReportFileStore, ReportFileStore>();
        services.AddScoped<ReportDataReader>();
        services.AddScoped<IReportGenerator, ReportGenerator>();

        return services;
    }

    private static IServiceCollection AddBillingModule(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        services.AddScoped<IPlanRepository, PlanRepository>();
        services.AddScoped<ISubscriptionRepository, SubscriptionRepository>();
        services.AddScoped<ICouponRepository, CouponRepository>();
        services.AddScoped<IBillingReadService, BillingReadService>();

        // Exactly one gateway. The stub (orders always succeed, signatures always verify) is Development-only; a real
        // configuration must carry all three secrets or startup fails.
        var razorpaySection = configuration.GetSection(RazorpayOptions.Section);
        if (string.IsNullOrWhiteSpace(razorpaySection[nameof(RazorpayOptions.KeyId)]))
        {
            if (!environment.IsDevelopment())
            {
                throw new InvalidOperationException(
                    $"'{RazorpayOptions.Section}:KeyId' is required outside Development. " +
                    "Set it via user-secrets or environment variables — never in appsettings.");
            }

            services.AddSingleton<IPaymentGateway, StubPaymentGateway>();
        }
        else
        {
            services.AddOptions<RazorpayOptions>().Bind(razorpaySection).ValidateDataAnnotations().ValidateOnStart();

            // The standard resilience handler owns timeouts (30 s total) and retries on transient failures; a retried
            // order POST can at worst leave an unused order behind on Razorpay's side.
            services.AddHttpClient(RazorpayPaymentGateway.HttpClientName, client =>
            {
                client.BaseAddress = new Uri("https://api.razorpay.com");
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            }).AddStandardResilienceHandler();

            services.AddSingleton<IPaymentGateway, RazorpayPaymentGateway>();
        }

        return services;
    }

    private static IServiceCollection AddIngestionModule(this IServiceCollection services, IConfiguration configuration, IHostEnvironment environment)
    {
        // Fail closed: mock data must never be ingested as real prices outside a developer machine.
        if (configuration.GetValue<bool>($"{AgmarknetOptions.SectionName}:{nameof(AgmarknetOptions.UseMockData)}") && !environment.IsDevelopment())
        {
            throw new InvalidOperationException(
                $"{AgmarknetOptions.SectionName}:UseMockData is allowed only in Development (current environment: '{environment.EnvironmentName}').");
        }

        services.AddScoped<IDataIngestionJobRepository, DataIngestionJobRepository>();
        services.AddScoped<IDataIngestionErrorRepository, DataIngestionErrorRepository>();
        services.AddScoped<IIngestionReadService, IngestionReadService>();

        // Keyed per PriceSource.Code; unknown codes fall back to the stub (construction sources until a feed exists).
        services.AddOptions<AgmarknetOptions>()
            .Bind(configuration.GetSection(AgmarknetOptions.SectionName))
            .Validate(o => o.PageSize is >= 1 and <= 1000, "Agmarknet:PageSize must be between 1 and 1000.")
            .Validate(o => o.ThrottleDelayMs is >= 0 and <= 10_000, "Agmarknet:ThrottleDelayMs must be between 0 and 10000.")
            .Validate(o => o.RequestTimeoutSeconds is >= 5 and <= 300, "Agmarknet:RequestTimeoutSeconds must be between 5 and 300.")
            .ValidateOnStart();

        services.AddHttpClient(AgmarknetIngestionSourceAdapter.HttpClientName, client =>
        {
            client.BaseAddress = new Uri(AgmarknetIngestionSourceAdapter.BaseAddress);
            client.DefaultRequestHeaders.Accept.ParseAdd("application/json");
        });

        services.AddKeyedScoped<IIngestionSourceAdapter, AgmarknetIngestionSourceAdapter>(AgmarknetIngestionSourceAdapter.SourceCode);
        services.AddKeyedScoped<IIngestionSourceAdapter, StubIngestionSourceAdapter>(IngestionAdapterDispatcher.FallbackKey);
        services.AddScoped<IIngestionSourceAdapter, IngestionAdapterDispatcher>();

        services.AddOptions<IngestionSchedulerOptions>()
            .Bind(configuration.GetSection(IngestionSchedulerOptions.SectionName))
            .Validate(o => o.IntervalHours is >= 1 and <= 168, "IngestionScheduler:IntervalHours must be between 1 and 168.")
            .ValidateOnStart();

        services.AddHostedService<IngestionSchedulerBackgroundService>();

        return services;
    }

    private static IServiceCollection AddLocalizationModule(this IServiceCollection services)
    {
        services.AddScoped<ILocalizedTextRepository, LocalizedTextEntryRepository>();
        services.AddScoped<ILocalizationReadService, LocalizationReadService>();

        return services;
    }

    private static IServiceCollection AddSupportModule(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<ISupportTicketRepository, SupportTicketRepository>();
        services.AddScoped<ISupportReadService, SupportReadService>();

        // Fail closed at startup: an unusable contact card is a broken help screen, not a runtime surprise.
        services.AddOptions<SupportOptions>()
            .Bind(configuration.GetSection(SupportOptions.SectionName))
            .Validate(
                o => SupportOptions.IsWhatsAppNumberValid(o.WhatsAppNumber),
                $"{SupportOptions.SectionName}:WhatsAppNumber must be an E.164 number of 8-15 digits, optionally written with '+', spaces or dashes.")
            .Validate(
                o => SupportOptions.IsPhoneValid(o.Phone),
                $"{SupportOptions.SectionName}:Phone must be a dialable number of 8-15 digits.")
            .Validate(
                o => SupportOptions.IsEmailValid(o.Email),
                $"{SupportOptions.SectionName}:Email must be a valid email address.")
            .ValidateOnStart();

        services.AddScoped<ISupportContactProvider, ConfiguredSupportContactProvider>();

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

            case OtpDeliveryProviders.Msg91:
                var msg91 = configuration.GetSection(Msg91Options.SectionName).Get<Msg91Options>() ?? new Msg91Options();

                if (!environment.IsDevelopment() && string.IsNullOrWhiteSpace(msg91.AuthKey))
                    throw new InvalidOperationException(
                        $"{Msg91Options.SectionName}:AuthKey is required in non-Development environments.");

                if (environment.IsDevelopment() && string.IsNullOrWhiteSpace(msg91.AuthKey))
                {
                    // Dev fallback: no real key configured, write codes to the log so the flow still works locally.
                    services.AddSingleton<IOtpSender, LoggingOtpSender>();
                }
                else
                {
                    services.Configure<Msg91Options>(configuration.GetSection(Msg91Options.SectionName));
                    services.AddHttpClient(Msg91OtpSender.HttpClientName,
                        c => c.BaseAddress = new Uri("https://control.msg91.com"));
                    services.AddSingleton<IOtpSender, Msg91OtpSender>();
                }
                break;

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
        SqlMapper.AddTypeHandler(new DateOnlyTypeHandler());
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
