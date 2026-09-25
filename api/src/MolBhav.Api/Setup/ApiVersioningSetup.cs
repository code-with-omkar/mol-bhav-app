using Asp.Versioning;

namespace MolBhav.Api.Setup;

internal static class ApiVersioningSetup
{
    public static IServiceCollection AddUrlSegmentVersioning(this IServiceCollection services)
    {
        services
            .AddApiVersioning(options =>
            {
                options.DefaultApiVersion = new ApiVersion(1, 0);
                options.AssumeDefaultVersionWhenUnspecified = false; // version is always explicit in the URL
                options.ReportApiVersions = true;                    // api-supported-versions / api-deprecated-versions headers
                options.ApiVersionReader = new UrlSegmentApiVersionReader();
            })
            .AddMvc()
            .AddApiExplorer(options =>
            {
                options.GroupNameFormat = "'v'V";          // document group "v1" → /openapi/v1.json
                options.SubstituteApiVersionInUrl = true; // "/api/v1/..." instead of "/api/v{version}/..."
            });

        return services;
    }
}
