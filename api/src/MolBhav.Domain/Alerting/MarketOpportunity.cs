using MolBhav.Domain.Alerting.Events;
using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Pricing;

namespace MolBhav.Domain.Alerting;

/// <summary>
/// A cheaper market for a product on the user's watchlist (BRD §13/§15): on <see cref="DetectedOn"/> (IST) the
/// <see cref="Best"/> market's price, plus the cost of bringing the goods in (<see cref="LandedPrice"/>), was at
/// least the configured percentage below the cheapest market in the user's home district (<see cref="Home"/>).
/// At most one per user, product and day. Immutable apart from the read flag — it is history, like <see cref="Alert"/>.
/// </summary>
public sealed class MarketOpportunity : AggregateRoot<Guid>, IAuditableEntity
{
    private MarketOpportunity(
        Guid id,
        Guid userId,
        Guid productId,
        Guid? variantId,
        DateOnly detectedOn,
        MarketLocation home,
        decimal homePrice,
        MarketLocation best,
        decimal bestPrice,
        decimal landedPrice,
        decimal savingsPercent,
        DateOnly priceDate,
        DateTimeOffset detectedAtUtc)
        : base(id)
    {
        UserId = userId;
        ProductId = productId;
        VariantId = variantId;
        DetectedOn = detectedOn;
        HomeLocationKind = home.Kind;
        HomeMandiId = home.MandiId;
        HomeSupplierId = home.SupplierId;
        HomePrice = homePrice;
        BestLocationKind = best.Kind;
        BestMandiId = best.MandiId;
        BestSupplierId = best.SupplierId;
        BestPrice = bestPrice;
        LandedPrice = landedPrice;
        SavingsPercent = savingsPercent;
        PriceDate = priceDate;
        DetectedAtUtc = detectedAtUtc;
        IsRead = false;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private MarketOpportunity()
    {
    }

    public Guid UserId { get; private set; }

    public Guid ProductId { get; private set; }

    /// <summary>The variant both prices are for (both sides are always the same variant).</summary>
    public Guid? VariantId { get; private set; }

    /// <summary>The IST day the scan found it — one opportunity per user/product/day.</summary>
    public DateOnly DetectedOn { get; private set; }

    public LocationKind HomeLocationKind { get; private set; }

    public Guid? HomeMandiId { get; private set; }

    public Guid? HomeSupplierId { get; private set; }

    /// <summary>Cheapest modal price in the user's home district, per the product's default unit.</summary>
    public decimal HomePrice { get; private set; }

    public LocationKind BestLocationKind { get; private set; }

    public Guid? BestMandiId { get; private set; }

    public Guid? BestSupplierId { get; private set; }

    /// <summary>Modal price at the cheaper market.</summary>
    public decimal BestPrice { get; private set; }

    /// <summary><see cref="BestPrice"/> plus freight/handling and other cost components, per unit.</summary>
    public decimal LandedPrice { get; private set; }

    /// <summary>(Home − Landed) / Home × 100.</summary>
    public decimal SavingsPercent { get; private set; }

    /// <summary>Record date of the cheaper market's price.</summary>
    public DateOnly PriceDate { get; private set; }

    public DateTimeOffset DetectedAtUtc { get; private set; }

    public bool IsRead { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>Price saved per unit after costs.</summary>
    public decimal SavingsPerUnit => HomePrice - LandedPrice;

    public static Result<MarketOpportunity> Create(
        Guid userId,
        Guid productId,
        Guid? variantId,
        DateOnly detectedOn,
        MarketLocation home,
        decimal homePrice,
        MarketLocation best,
        decimal bestPrice,
        decimal landedPrice,
        DateOnly priceDate,
        DateTimeOffset detectedAtUtc)
    {
        if (userId == Guid.Empty || productId == Guid.Empty)
        {
            return Error.Validation("MarketOpportunity.Required", "User and product are required.");
        }

        if (!home.IsValid || !best.IsValid)
        {
            return Error.Validation("MarketOpportunity.InvalidLocation", "Home and best markets must each be one mandi or one supplier.");
        }

        if (home == best)
        {
            return Error.Validation("MarketOpportunity.SameMarket", "The cheaper market must differ from the home market.");
        }

        if (homePrice <= 0 || bestPrice <= 0 || landedPrice < bestPrice)
        {
            return Error.Validation("MarketOpportunity.InvalidPrice", "Prices must be positive and the landed price cannot be below the market price.");
        }

        if (landedPrice >= homePrice)
        {
            return Error.Validation("MarketOpportunity.NoSaving", "The landed price must be below the home price.");
        }

        var savingsPercent = decimal.Round((homePrice - landedPrice) / homePrice * 100m, 2, MidpointRounding.AwayFromZero);

        var opportunity = new MarketOpportunity(
            Guid.CreateVersion7(),
            userId,
            productId,
            variantId,
            detectedOn,
            home,
            homePrice,
            best,
            bestPrice,
            landedPrice,
            savingsPercent,
            priceDate,
            detectedAtUtc);

        opportunity.RaiseDomainEvent(new MarketOpportunityFoundDomainEvent(
            opportunity.Id,
            userId,
            productId,
            variantId,
            homePrice,
            bestPrice,
            landedPrice,
            savingsPercent));

        return opportunity;
    }

    public void MarkRead() => IsRead = true;
}

/// <summary>One mandi or one supplier — the same two-nullable-FK shape as <see cref="PriceRecord"/>.</summary>
public readonly record struct MarketLocation(LocationKind Kind, Guid? MandiId, Guid? SupplierId)
{
    public static MarketLocation Mandi(Guid mandiId) => new(LocationKind.Mandi, mandiId, null);

    public static MarketLocation Supplier(Guid supplierId) => new(LocationKind.Supplier, null, supplierId);

    public Guid Id => MandiId ?? SupplierId ?? Guid.Empty;

    public bool IsValid => Kind switch
    {
        LocationKind.Mandi => MandiId is { } m && m != Guid.Empty && SupplierId is null,
        LocationKind.Supplier => SupplierId is { } s && s != Guid.Empty && MandiId is null,
        _ => false,
    };
}
