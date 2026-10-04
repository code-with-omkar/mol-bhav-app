using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Persistence.Repositories.Ingestion;

internal sealed class IngestionScheduleRepository(MolBhavDbContext dbContext)
    : Repository<IngestionSchedule, Guid>(dbContext), IIngestionScheduleRepository
{
    public Task<IngestionSchedule?> GetByPriceSourceIdAsync(Guid priceSourceId, CancellationToken cancellationToken = default) =>
        Set.SingleOrDefaultAsync(s => s.PriceSourceId == priceSourceId, cancellationToken);

    public async Task<IReadOnlyList<Guid>> GetDueIdsAsync(DateTimeOffset nowUtc, int limit, CancellationToken cancellationToken = default) =>
        await Set.AsNoTracking()
            .Where(s => s.IsEnabled && s.NextRunAtUtc != null && s.NextRunAtUtc <= nowUtc)
            .OrderBy(s => s.NextRunAtUtc)
            .Select(s => s.Id)
            .Take(limit)
            .ToArrayAsync(cancellationToken);
}
