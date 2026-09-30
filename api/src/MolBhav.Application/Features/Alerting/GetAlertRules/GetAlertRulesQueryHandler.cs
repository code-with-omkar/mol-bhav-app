using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Alerting.Models;
using MolBhav.Application.Features.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Alerting.GetAlertRules;

internal sealed class GetAlertRulesQueryHandler(IAlertingReadService readService, ICurrentUser currentUser, ILanguageContext languageContext)
    : IQueryHandler<GetAlertRulesQuery, IReadOnlyList<AlertRuleResponse>>
{
    public async Task<Result<IReadOnlyList<AlertRuleResponse>>> Handle(GetAlertRulesQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAlertRulesAsync(currentUser.GetRequiredUserId(), CatalogLanguage.From(languageContext), cancellationToken));
}
