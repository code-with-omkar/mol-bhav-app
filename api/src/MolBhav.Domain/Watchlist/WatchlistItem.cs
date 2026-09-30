using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Watchlist;

/// <summary>
/// A product (or variant) a user is monitoring (BRD §7/§10: smart commodity watchlist). No separate "Watchlist"
/// aggregate — a user's watched items are simply their rows here, one per product/variant, across every enabled
/// category (BRD §7: "One user can maintain watchlists across one or more enabled procurement categories").
/// Removed by hard delete: unlike catalog/market/pricing data, a watchlist entry carries no history worth keeping.
/// </summary>
public sealed class WatchlistItem : AggregateRoot<Guid>, IAuditableEntity
{
    private WatchlistItem(Guid id, Guid userId, Guid productId, Guid? variantId)
        : base(id)
    {
        UserId = userId;
        ProductId = productId;
        VariantId = variantId;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private WatchlistItem()
    {
    }

    public Guid UserId { get; private set; }

    public Guid ProductId { get; private set; }

    /// <summary>Optional: watch a specific variant (e.g. a particular onion grade) rather than the whole product.</summary>
    public Guid? VariantId { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>The caller guarantees <paramref name="productId"/>/<paramref name="variantId"/> exist and belong together; the database FKs are the backstop.</summary>
    public static Result<WatchlistItem> Create(Guid userId, Guid productId, Guid? variantId)
    {
        if (userId == Guid.Empty)
        {
            return Error.Validation("WatchlistItem.UserRequired", "User is required.");
        }

        if (productId == Guid.Empty)
        {
            return Error.Validation("WatchlistItem.ProductRequired", "Product is required.");
        }

        return new WatchlistItem(Guid.CreateVersion7(), userId, productId, variantId);
    }
}
