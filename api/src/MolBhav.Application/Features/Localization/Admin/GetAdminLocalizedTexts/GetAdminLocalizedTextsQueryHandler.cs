using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Localization.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Localization.Admin.GetAdminLocalizedTexts;

internal sealed class GetAdminLocalizedTextsQueryHandler(ILocalizationReadService readService)
    : IQueryHandler<GetAdminLocalizedTextsQuery, PagedResult<AdminLocalizedTextResponse>>
{
    public async Task<Result<PagedResult<AdminLocalizedTextResponse>>> Handle(GetAdminLocalizedTextsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminTextsAsync(
            new AdminLocalizedTextFilter(
                string.IsNullOrWhiteSpace(request.KeyPrefix) ? null : request.KeyPrefix.Trim().ToLowerInvariant(),
                new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
}
