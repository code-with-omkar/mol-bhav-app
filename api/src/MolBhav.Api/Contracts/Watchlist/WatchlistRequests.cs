namespace MolBhav.Api.Contracts.Watchlist;

/// <param name="ProductId">The product to watch.</param>
/// <param name="VariantId">Optional: watch a specific variant instead of the whole product.</param>
public sealed record AddToWatchlistRequest(Guid? ProductId, Guid? VariantId);
