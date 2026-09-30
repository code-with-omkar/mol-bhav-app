using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Localization.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Localization.Admin.GetAdminLocalizedText;

internal sealed class GetAdminLocalizedTextQueryHandler(ILocalizationReadService readService)
    : IQueryHandler<GetAdminLocalizedTextQuery, AdminLocalizedTextResponse>
{
    public async Task<Result<AdminLocalizedTextResponse>> Handle(GetAdminLocalizedTextQuery request, CancellationToken cancellationToken) =>
        Result.FromNullable(
            await readService.GetAdminTextAsync(request.LocalizedTextId, cancellationToken),
            Error.NotFound("LocalizedTextEntry.NotFound", "Localized text not found."));
}
