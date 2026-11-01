using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Domain.Alerting;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Alerting;

internal sealed class MarketOpportunityRepository(MolBhavDbContext dbContext)
    : Repository<MarketOpportunity, Guid>(dbContext), IMarketOpportunityRepository
{
    public async Task<IReadOnlySet<(Guid UserId, Guid ProductId)>> GetFoundOnAsync(
        DateOnly detectedOn,
        CancellationToken cancellationToken = default)
    {
        var pairs = await Set.AsNoTracking()
            .Where(o => o.DetectedOn == detectedOn)
            .Select(o => new { o.UserId, o.ProductId })
            .ToListAsync(cancellationToken);

        return pairs.Select(p => (p.UserId, p.ProductId)).ToHashSet();
    }
}
