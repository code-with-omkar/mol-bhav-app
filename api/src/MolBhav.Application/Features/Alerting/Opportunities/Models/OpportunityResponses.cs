using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Alerting.Opportunities.Models;

/// <summary>One side of an opportunity: the home-district market or the cheaper one.</summary>
public sealed record OpportunityMarketResponse(
    LocationKind LocationKind,
    Guid LocationId,
    string Name,
    string DistrictName,
    decimal Price);

public sealed record MarketOpportunityResponse(
    Guid Id,
    ProductSummaryResponse Product,
    Guid? VariantId,
    string? VariantName,
    OpportunityMarketResponse Home,
    OpportunityMarketResponse Best,
    decimal LandedPrice,
    decimal SavingsPercent,
    decimal SavingsPerUnit,
    DateOnly PriceDate,
    DateOnly DetectedOn,
    DateTimeOffset DetectedAtUtc,
    bool IsRead);

/// <summary>Every market's current price for the opportunity's product/variant, with its landed price.</summary>
public sealed record OpportunityMarketPriceResponse(
    LocationKind LocationKind,
    Guid LocationId,
    string Name,
    string DistrictName,
    decimal ModalPrice,
    decimal LandedPrice,
    bool IsHomeDistrict,
    DateOnly RecordDate);

/// <param name="ReferenceQuantity">Order size (default unit) the landed prices assume; also used to show the saving
/// for a typical order.</param>
public sealed record MarketOpportunityDetailResponse(
    MarketOpportunityResponse Opportunity,
    IReadOnlyList<OpportunityMarketPriceResponse> Markets,
    decimal ReferenceQuantity);
