using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Models;

namespace MolBhav.Application.Abstractions.Alerting;

/// <summary>Dapper-backed reads for the signed-in user's alert rules and triggered alerts.</summary>
public interface IAlertingReadService
{
    Task<IReadOnlyList<AlertRuleResponse>> GetAlertRulesAsync(Guid userId, LanguagePreference language, CancellationToken cancellationToken = default);

    Task<PagedResult<AlertResponse>> GetAlertsAsync(Guid userId, LanguagePreference language, PageRequest page, CancellationToken cancellationToken = default);
}
