using System.Diagnostics;
using System.Text.Json.Serialization;
using MolBhav.Api.ErrorHandling;
using MolBhav.Api.Services;
using MolBhav.Api.Setup;
using MolBhav.Api.Setup.OpenApi;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Localization;

namespace MolBhav.Api;

public static class DependencyInjection
{
    public static IServiceCollection AddPresentation(this IServiceCollection services, IConfiguration configuration)
    {
        services
            .AddControllers()
            .AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
                options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
            });

        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUser, CurrentUser>();
        services.AddScoped<ILanguageContext, RequestLanguageContext>();

        services.AddExceptionHandler<GlobalExceptionHandler>();
        services.AddProblemDetails(options => options.CustomizeProblemDetails = context =>
        {
            var request = context.HttpContext.Request;
            context.ProblemDetails.Instance ??= $"{request.Method} {request.Path}";
            context.ProblemDetails.Extensions.TryAdd(
                ProblemDetailsExtensionKeys.TraceId,
                Activity.Current?.Id ?? context.HttpContext.TraceIdentifier);
        });

        services
            .AddUrlSegmentVersioning()
            .AddApiAuthorization()
            .AddApiRateLimiting(configuration)
            .AddScopedCors(configuration)
            .AddRequestLanguageNegotiation(configuration)
            .AddReverseProxySupport(configuration)
            .AddVersionedOpenApi();

        services.AddHsts(options =>
        {
            options.MaxAge = TimeSpan.FromDays(365);
            options.IncludeSubDomains = true;
        });

        return services;
    }
}
