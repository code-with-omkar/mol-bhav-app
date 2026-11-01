using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.Models;

/// <summary>One location's latest price for a product — a row in the comparison matrix (BRD §10/§11/§12).</summary>
public sealed record LatestPriceResponse(
    LocationKind LocationKind,
    Guid LocationId,
    string LocationName,
    string DistrictName,
    string StateName,
    decimal? MinPrice,
    decimal? MaxPrice,
    decimal ModalPrice,
    string UnitCode,
    string UnitSymbol,
    decimal? ArrivalQuantity,
    DateOnly RecordDate,
    string SourceName);

/// <summary>One product/variant's latest price at a single mandi/supplier — a row in browse-by-mandi.</summary>
public sealed record LocationLatestPriceResponse(
    Guid ProductId,
    string ProductName,
    Guid? VariantId,
    string? VariantName,
    decimal? MinPrice,
    decimal? MaxPrice,
    decimal ModalPrice,
    string UnitCode,
    string UnitSymbol,
    decimal? ArrivalQuantity,
    DateOnly RecordDate,
    string SourceName);

public sealed record PriceHistoryPointResponse(DateOnly RecordDate, decimal? MinPrice, decimal? MaxPrice, decimal ModalPrice);

/// <summary>
/// Whether the automatically refreshed price feeds are keeping up, for the app's "prices may be delayed" banner.
/// <paramref name="LastUpdatedAtUtc"/> is when a feed last brought data in (null if none ever has).
/// </summary>
public sealed record PriceDataStatusResponse(bool IsDelayed, DateTimeOffset? LastUpdatedAtUtc);
