using Microsoft.OpenApi;

namespace MolBhav.Api.Setup.OpenApi;

internal static class OpenApiSetup
{
    /// <summary>One document per API version group; add "v2" here when a v2 controller ships.</summary>
    public static readonly string[] Documents = ["v1"];

    public static IServiceCollection AddVersionedOpenApi(this IServiceCollection services)
    {
        foreach (var documentName in Documents)
        {
            services.AddOpenApi(documentName, options =>
            {
                options.AddDocumentTransformer<BearerSecuritySchemeTransformer>();
                options.AddDocumentTransformer((document, _, _) =>
                {
                    document.Info = new OpenApiInfo
                    {
                        Title = "MolBhav API",
                        Version = documentName,
                        Description = "Market & Procurement Intelligence — मोल समझो, भाव परखो, बेहतर खरीदो।",
                    };
                    return Task.CompletedTask;
                });
            });
        }

        return services;
    }
}
