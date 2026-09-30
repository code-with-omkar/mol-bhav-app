using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Localization.GetLocalizedTexts;

internal sealed class GetLocalizedTextsQueryHandler(ILocalizationReadService readService, ILanguageContext languageContext)
    : IQueryHandler<GetLocalizedTextsQuery, IReadOnlyDictionary<string, string>>
{
    public async Task<Result<IReadOnlyDictionary<string, string>>> Handle(GetLocalizedTextsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetTextsAsync(
            languageContext.CurrentLanguage,
            string.IsNullOrWhiteSpace(request.KeyPrefix) ? null : request.KeyPrefix.Trim().ToLowerInvariant(),
            cancellationToken));
}
