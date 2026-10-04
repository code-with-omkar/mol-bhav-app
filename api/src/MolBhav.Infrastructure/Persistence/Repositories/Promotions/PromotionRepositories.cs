using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Domain.Promotions;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Promotions;

internal sealed class AdvertiserRepository(MolBhavDbContext dbContext)
    : Repository<Advertiser, Guid>(dbContext), IAdvertiserRepository
{
}

internal sealed class CampaignRepository(MolBhavDbContext dbContext)
    : Repository<Campaign, Guid>(dbContext), ICampaignRepository
{
    /// <summary>Loads the whole aggregate: the campaign plus its targets.</summary>
    public override Task<Campaign?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Set.Include(c => c.Targets).SingleOrDefaultAsync(c => c.Id == id, cancellationToken);
}
