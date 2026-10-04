using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Abstractions.Promotions;

public interface IAdvertiserRepository : IRepository<Advertiser, Guid>
{
}

/// <summary><see cref="IRepository{TAggregate,TId}.GetByIdAsync"/> loads the campaign with its targets.</summary>
public interface ICampaignRepository : IRepository<Campaign, Guid>
{
}
