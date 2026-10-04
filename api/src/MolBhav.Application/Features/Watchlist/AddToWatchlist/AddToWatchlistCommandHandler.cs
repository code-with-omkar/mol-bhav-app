using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Watchlist;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Monetization;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Monetization;
using MolBhav.Domain.Watchlist;

namespace MolBhav.Application.Features.Watchlist.AddToWatchlist;

internal sealed class AddToWatchlistCommandHandler(
    IWatchlistItemRepository watchlistItems,
    IProductRepository products,
    IEntitlementService entitlements,
    ICurrentUser currentUser)
    : ICommandHandler<AddToWatchlistCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(AddToWatchlistCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();

        var product = await products.GetByIdAsync(request.ProductId, cancellationToken);
        if (product is null)
        {
            return Error.NotFound("Product.NotFound", "Product not found.");
        }

        if (request.VariantId is { } variantId && product.Variants.All(v => v.Id != variantId))
        {
            return Error.Validation("ProductVariant.NotFound", "Variant does not belong to this product.");
        }

        // Friendly pre-check; the (user_id, product_id, variant_id) index keeps the read cheap either way.
        if (await watchlistItems.ExistsAsync(userId, request.ProductId, request.VariantId, cancellationToken))
        {
            return Error.Conflict("WatchlistItem.AlreadyWatched", "This item is already on your watchlist.");
        }

        // Free tier: capacity grows with rewarded-ad unlocks; Pro is unlimited.
        var allowed = await entitlements.EnsureCanAddAsync(MonetizedFeature.WatchlistSlots, cancellationToken);
        if (allowed.IsFailure)
        {
            return Result.Failure<CreatedResponse>(allowed.Error);
        }

        var item = WatchlistItem.Create(userId, request.ProductId, request.VariantId);
        if (item.IsFailure)
        {
            return Result.Failure<CreatedResponse>(item.Error);
        }

        watchlistItems.Add(item.Value);
        return new CreatedResponse(item.Value.Id);
    }
}
