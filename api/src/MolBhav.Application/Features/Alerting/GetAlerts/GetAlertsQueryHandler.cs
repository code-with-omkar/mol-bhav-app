using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Models;
using MolBhav.Application.Features.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Alerting.GetAlerts;

internal sealed class GetAlertsQueryHandler(IAlertingReadService readService, ICurrentUser currentUser, ILanguageContext languageContext)
    : IQueryHandler<GetAlertsQuery, PagedResult<AlertResponse>>
{
    public async Task<Result<PagedResult<AlertResponse>>> Handle(GetAlertsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAlertsAsync(
            currentUser.GetRequiredUserId(),
            CatalogLanguage.From(languageContext),
            new PageRequest(request.Page, request.PageSize),
            cancellationToken));
}
