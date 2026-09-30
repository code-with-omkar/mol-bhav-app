using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Watchlist;

namespace MolBhav.Application.Abstractions.Watchlist;

public interface IWatchlistItemRepository : IRepository<WatchlistItem, Guid>
{
    Task<bool> ExistsAsync(Guid userId, Guid productId, Guid? variantId, CancellationToken cancellationToken = default);
}
