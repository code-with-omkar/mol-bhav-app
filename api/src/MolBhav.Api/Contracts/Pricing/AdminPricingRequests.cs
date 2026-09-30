using MolBhav.Domain.Pricing;

namespace MolBhav.Api.Contracts.Pricing;

// Admin portal request bodies. isActive is nullable so a missing field reaches FluentValidation instead of
// silently binding to false — an omitted isActive must never deactivate an item.

/// <param name="Code">Immutable, e.g. <c>agmarknet</c>.</param>
/// <param name="Name">Display name.</param>
public sealed record CreatePriceSourceRequest(string? Code, string? Name);

public sealed record UpdatePriceSourceRequest(string? Name, bool? IsActive);

/// <param name="ProductId">The product this price is for.</param>
/// <param name="VariantId">Optional variant of the product.</param>
/// <param name="UnitId">Unit the prices are quoted in.</param>
/// <param name="LocationKind">Whether this is a mandi (agriculture) or supplier (construction) price.</param>
/// <param name="MandiId">Required when <paramref name="LocationKind"/> is <see cref="Domain.Pricing.LocationKind.Mandi"/>.</param>
/// <param name="SupplierId">Required when <paramref name="LocationKind"/> is <see cref="Domain.Pricing.LocationKind.Supplier"/>.</param>
/// <param name="PriceSourceId">Where this price came from.</param>
/// <param name="MinPrice">Optional day low.</param>
/// <param name="MaxPrice">Optional day high.</param>
/// <param name="ModalPrice">The representative/most-traded price.</param>
/// <param name="ArrivalQuantity">Optional quantity traded (agriculture arrivals).</param>
/// <param name="RecordDate">The date this price was observed.</param>
public sealed record RecordPriceRequest(
    Guid? ProductId,
    Guid? VariantId,
    Guid? UnitId,
    LocationKind? LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    Guid? PriceSourceId,
    decimal? MinPrice,
    decimal? MaxPrice,
    decimal? ModalPrice,
    decimal? ArrivalQuantity,
    DateOnly? RecordDate);
