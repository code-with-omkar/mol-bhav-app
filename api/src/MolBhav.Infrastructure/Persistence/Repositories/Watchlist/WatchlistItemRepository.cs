using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Watchlist;
using MolBhav.Domain.Watchlist;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Watchlist;

internal sealed class WatchlistItemRepository(MolBhavDbContext dbContext) : Repository<WatchlistItem, Guid>(dbContext), IWatchlistItemRepository
{
    public Task<bool> ExistsAsync(Guid userId, Guid productId, Guid? variantId, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(w => w.UserId == userId && w.ProductId == productId && w.VariantId == variantId, cancellationToken);

    // Served by the (user_id, product_id, variant_id) index's leading column.
    public Task<int> CountByUserAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Set.CountAsync(w => w.UserId == userId, cancellationToken);
}
