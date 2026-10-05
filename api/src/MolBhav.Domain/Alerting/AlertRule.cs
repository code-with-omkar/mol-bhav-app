using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Pricing;

namespace MolBhav.Domain.Alerting;

/// <summary>
/// A user's standing watch on a product's price (BRD §15: custom threshold / price-drop / price-spike / watchlist
/// alerts). Scope is either the whole product (<see cref="LocationKind"/> null — any location triggers it) or one
/// specific mandi/supplier. Evaluated by <c>EvaluateAlertRulesHandler</c> whenever a new price is recorded.
/// Hard-deleted like <c>WatchlistItem</c> — a rule carries no history worth keeping once removed.
/// </summary>
public sealed class AlertRule : AggregateRoot<Guid>, IAuditableEntity
{
    public const decimal MinThresholdPercent = 0.01m;
    public const decimal MaxThresholdPercent = 100m;
    public const decimal MinThresholdPrice = 0.01m;
    public const decimal MaxThresholdPrice = 999_999_999_999.99m;

    private AlertRule(
        Guid id,
        Guid userId,
        Guid productId,
        Guid? variantId,
        LocationKind? locationKind,
        Guid? mandiId,
        Guid? supplierId,
        AlertThresholdType thresholdType,
        decimal? thresholdPercent,
        decimal? thresholdPrice)
        : base(id)
    {
        UserId = userId;
        ProductId = productId;
        VariantId = variantId;
        LocationKind = locationKind;
        MandiId = mandiId;
        SupplierId = supplierId;
        ThresholdType = thresholdType;
        ThresholdPercent = thresholdPercent;
        ThresholdPrice = thresholdPrice;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private AlertRule()
    {
    }

    public Guid UserId { get; private set; }

    public Guid ProductId { get; private set; }

    public Guid? VariantId { get; private set; }

    /// <summary>Null scopes the rule to the whole product (any mandi/supplier); set narrows it to one location.</summary>
    public LocationKind? LocationKind { get; private set; }

    public Guid? MandiId { get; private set; }

    public Guid? SupplierId { get; private set; }

    public AlertThresholdType ThresholdType { get; private set; }

    /// <summary>
    /// Percent change (0, 100] that triggers the alert, e.g. 10 = a 10% drop/spike/either-way move vs. the previous price.
    /// Set for the percent types only — null for <see cref="AlertThresholdType.PriceBelow"/>/<see cref="AlertThresholdType.PriceAbove"/>.
    /// </summary>
    public decimal? ThresholdPercent { get; private set; }

    /// <summary>
    /// Absolute price level the rule watches, e.g. 2400 = "tell me when it drops below ₹2,400".
    /// Set for the price types only — null for <see cref="AlertThresholdType.PriceDrop"/>/<see cref="AlertThresholdType.PriceSpike"/>.
    /// </summary>
    public decimal? ThresholdPrice { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<AlertRule> Create(
        Guid userId,
        Guid productId,
        Guid? variantId,
        LocationKind? locationKind,
        Guid? mandiId,
        Guid? supplierId,
        AlertThresholdType thresholdType,
        decimal? thresholdPercent,
        decimal? thresholdPrice)
    {
        if (userId == Guid.Empty || productId == Guid.Empty)
        {
            return Error.Validation("AlertRule.ReferenceRequired", "User and product are required.");
        }

        var locationCheck = ValidateLocation(locationKind, mandiId, supplierId);
        if (locationCheck.IsFailure)
        {
            return Result.Failure<AlertRule>(locationCheck.Error);
        }

        var thresholdCheck = ValidateThreshold(thresholdType, thresholdPercent, thresholdPrice);
        if (thresholdCheck.IsFailure)
        {
            return Result.Failure<AlertRule>(thresholdCheck.Error);
        }

        return new AlertRule(
            Guid.CreateVersion7(), userId, productId, variantId, locationKind, mandiId, supplierId, thresholdType, thresholdPercent, thresholdPrice);
    }

    /// <summary>True when <paramref name="thresholdType"/> is measured as a percent move rather than a rupee level.</summary>
    public static bool IsPercentType(AlertThresholdType thresholdType) =>
        thresholdType is AlertThresholdType.PriceDrop or AlertThresholdType.PriceSpike or AlertThresholdType.PriceChange;

    /// <summary>
    /// The threshold a rule carries is fixed by its <see cref="ThresholdType"/>, so an update sets whichever of the
    /// two the type calls for — passing the wrong one (or both) fails rather than silently leaving the rule unchanged.
    /// </summary>
    public Result Update(decimal? thresholdPercent, decimal? thresholdPrice, bool isActive)
    {
        var thresholdCheck = ValidateThreshold(ThresholdType, thresholdPercent, thresholdPrice);
        if (thresholdCheck.IsFailure)
        {
            return thresholdCheck;
        }

        ThresholdPercent = thresholdPercent;
        ThresholdPrice = thresholdPrice;
        IsActive = isActive;
        return Result.Success();
    }

    /// <summary>True when a price recorded at the given location falls within this rule's scope.</summary>
    public bool Matches(Guid productId, Guid? variantId, Pricing.LocationKind locationKind, Guid? mandiId, Guid? supplierId)
    {
        if (!IsActive || ProductId != productId)
        {
            return false;
        }

        if (VariantId is not null && VariantId != variantId)
        {
            return false;
        }

        // Product-wide rule (LocationKind null): any location matches. Scoped rule: same location only.
        return LocationKind is null || (LocationKind == locationKind && MandiId == mandiId && SupplierId == supplierId);
    }

    /// <summary>A percent type carries exactly a percent, a price type exactly a price — never both, never neither.</summary>
    private static Result ValidateThreshold(AlertThresholdType thresholdType, decimal? thresholdPercent, decimal? thresholdPrice)
    {
        if (IsPercentType(thresholdType))
        {
            if (thresholdPrice is not null)
            {
                return Error.Validation("AlertRule.PriceNotAllowed", "A percent-change rule must not set a threshold price.");
            }

            return thresholdPercent is not { } percent || percent < MinThresholdPercent || percent > MaxThresholdPercent
                ? Error.Validation(
                    "AlertRule.InvalidThreshold",
                    $"Threshold must be between {MinThresholdPercent} and {MaxThresholdPercent} percent.")
                : Result.Success();
        }

        if (thresholdPercent is not null)
        {
            return Error.Validation("AlertRule.PercentNotAllowed", "A price-level rule must not set a threshold percent.");
        }

        return thresholdPrice is not { } price || price < MinThresholdPrice || price > MaxThresholdPrice
            ? Error.Validation(
                "AlertRule.InvalidThresholdPrice",
                $"Threshold price must be between {MinThresholdPrice} and {MaxThresholdPrice}.")
            : Result.Success();
    }

    private static Result ValidateLocation(LocationKind? locationKind, Guid? mandiId, Guid? supplierId)
    {
        if (locationKind is null)
        {
            return mandiId is null && supplierId is null
                ? Result.Success()
                : Error.Validation("AlertRule.LocationNotAllowed", "A product-wide rule must not set a mandi or supplier.");
        }

        var hasMandi = mandiId is { } m && m != Guid.Empty;
        var hasSupplier = supplierId is { } s && s != Guid.Empty;

        return locationKind switch
        {
            Pricing.LocationKind.Mandi when !hasMandi || hasSupplier =>
                Error.Validation("AlertRule.MandiRequired", "A mandi-scoped rule requires exactly a mandi id."),
            Pricing.LocationKind.Supplier when !hasSupplier || hasMandi =>
                Error.Validation("AlertRule.SupplierRequired", "A supplier-scoped rule requires exactly a supplier id."),
            Pricing.LocationKind.Mandi or Pricing.LocationKind.Supplier => Result.Success(),
            _ => Error.Validation("AlertRule.InvalidLocationKind", "Unknown location kind."),
        };
    }
}
