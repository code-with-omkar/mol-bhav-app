using System.Reflection;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Diagnostics.GetApiStatus;

internal sealed class GetApiStatusQueryHandler(TimeProvider timeProvider, ILanguageContext languageContext)
    : IQueryHandler<GetApiStatusQuery, ApiStatusResponse>
{
    private static readonly string Version =
        typeof(GetApiStatusQueryHandler).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion
        ?? "0.0.0";

    public Task<Result<ApiStatusResponse>> Handle(GetApiStatusQuery request, CancellationToken cancellationToken)
    {
        var response = new ApiStatusResponse(
            Service: "MolBhav API",
            Version: Version,
            Language: languageContext.CurrentLanguage,
            ServerTimeUtc: timeProvider.GetUtcNow());

        return Task.FromResult(Result.Success(response));
    }
}
