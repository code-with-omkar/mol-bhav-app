using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Persistence.Repositories.Ingestion;

internal sealed class SourceFeedOptionsRepository(MolBhavDbContext dbContext)
    : Repository<SourceFeedOptions, Guid>(dbContext), ISourceFeedOptionsRepository
{
    public Task<SourceFeedOptions?> GetByPriceSourceIdAsync(Guid priceSourceId, CancellationToken cancellationToken = default) =>
        Set.SingleOrDefaultAsync(o => o.PriceSourceId == priceSourceId, cancellationToken);
}
