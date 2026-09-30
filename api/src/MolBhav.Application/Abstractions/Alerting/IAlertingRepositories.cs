using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Alerting;

namespace MolBhav.Application.Abstractions.Alerting;

public interface IAlertRuleRepository : IRepository<AlertRule, Guid>
{
    /// <summary>Every active rule for the product, evaluated in memory against <see cref="AlertRule.Matches"/> —
    /// the rule count per product is small enough that a DB-side filter on the full location tuple isn't worth it.</summary>
    Task<IReadOnlyList<AlertRule>> GetActiveByProductAsync(Guid productId, CancellationToken cancellationToken = default);
}

public interface IAlertRepository : IRepository<Alert, Guid>
{
}
