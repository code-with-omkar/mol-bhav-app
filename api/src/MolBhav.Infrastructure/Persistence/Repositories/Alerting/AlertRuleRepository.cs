using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Domain.Alerting;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Alerting;

internal sealed class AlertRuleRepository(MolBhavDbContext dbContext) : Repository<AlertRule, Guid>(dbContext), IAlertRuleRepository
{
    public async Task<IReadOnlyList<AlertRule>> GetActiveByProductAsync(Guid productId, CancellationToken cancellationToken = default) =>
        await Set.AsNoTracking()
            .Where(r => r.ProductId == productId && r.IsActive)
            .ToArrayAsync(cancellationToken);
}
