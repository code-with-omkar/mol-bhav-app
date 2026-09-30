using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Billing;

public enum DiscountType
{
    Percent = 0,
    Fixed = 1,
}

/// <summary>
/// A promotional code that discounts a plan subscription. Validating a coupon never consumes it; a use is counted
/// only when the discounted subscription is activated, through an atomic database increment that enforces
/// <see cref="MaxUses"/> under concurrency.
/// </summary>
public sealed class Coupon : AggregateRoot<Guid>, IAuditableEntity
{
    public const int CodeMaxLength = 50;

    /// <summary>Razorpay rejects orders below ₹1, so a discount never takes the charge under this.</summary>
    public const long MinimumChargePaise = 100;

    private Coupon(Guid id, string code, DiscountType discountType, long discountValue,
        int? maxUses, DateTimeOffset validFrom, DateTimeOffset? validTo,
        string? applicablePlanCode, long minAmountPaise)
        : base(id)
    {
        Code = code;
        DiscountType = discountType;
        DiscountValue = discountValue;
        MaxUses = maxUses;
        ValidFrom = validFrom;
        ValidTo = validTo;
        ApplicablePlanCode = applicablePlanCode;
        MinAmountPaise = minAmountPaise;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Coupon()
    {
        Code = string.Empty;
    }

    /// <summary>Stored upper-case; lookups normalise with <see cref="NormaliseCode"/>.</summary>
    public string Code { get; private set; }

    public DiscountType DiscountType { get; private set; }

    /// <summary>Percent (1–100) or a fixed amount in paise, depending on <see cref="DiscountType"/>.</summary>
    public long DiscountValue { get; private set; }

    /// <summary>Maximum redemptions; <c>null</c> = unlimited.</summary>
    public int? MaxUses { get; private set; }

    public int UsesCount { get; private set; }

    public DateTimeOffset ValidFrom { get; private set; }

    public DateTimeOffset? ValidTo { get; private set; }

    /// <summary><c>null</c> = applicable to any plan.</summary>
    public string? ApplicablePlanCode { get; private set; }

    /// <summary>The plan price must be at least this for the coupon to apply.</summary>
    public long MinAmountPaise { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static string NormaliseCode(string code) => code.Trim().ToUpperInvariant();

    public static Result<Coupon> Create(
        string? code, DiscountType discountType, long discountValue,
        int? maxUses, DateTimeOffset validFrom, DateTimeOffset? validTo,
        string? applicablePlanCode, long minAmountPaise)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return Error.Validation("Coupon.CodeRequired", "Coupon code is required.");
        }

        var normalised = NormaliseCode(code);
        if (normalised.Length > CodeMaxLength)
        {
            return Error.Validation("Coupon.CodeTooLong", $"Coupon code must be at most {CodeMaxLength} characters.");
        }

        if (discountValue <= 0)
        {
            return Error.Validation("Coupon.InvalidDiscount", "Discount value must be positive.");
        }

        if (discountType == DiscountType.Percent && discountValue > 100)
        {
            return Error.Validation("Coupon.InvalidPercent", "Percent discount must be between 1 and 100.");
        }

        if (maxUses is <= 0)
        {
            return Error.Validation("Coupon.InvalidMaxUses", "Max uses must be positive when set.");
        }

        if (validTo.HasValue && validTo <= validFrom)
        {
            return Error.Validation("Coupon.InvalidValidity", "Valid-to must be after valid-from.");
        }

        if (minAmountPaise < 0)
        {
            return Error.Validation("Coupon.InvalidMinAmount", "Minimum amount must not be negative.");
        }

        var planCode = string.IsNullOrWhiteSpace(applicablePlanCode) ? null : applicablePlanCode.Trim();

        return new Coupon(Guid.CreateVersion7(), normalised, discountType, discountValue,
            maxUses, validFrom, validTo, planCode, minAmountPaise);
    }

    /// <summary>Admin edit: toggle, extend validity, or change the usage cap (never below uses already made).</summary>
    public Result Update(bool isActive, DateTimeOffset? validTo, int? maxUses)
    {
        if (validTo.HasValue && validTo <= ValidFrom)
        {
            return Error.Validation("Coupon.InvalidValidity", "Valid-to must be after valid-from.");
        }

        if (maxUses.HasValue && maxUses < UsesCount)
        {
            return BillingErrors.CouponMaxUsesBelowUsage;
        }

        if (maxUses is <= 0)
        {
            return Error.Validation("Coupon.InvalidMaxUses", "Max uses must be positive when set.");
        }

        IsActive = isActive;
        ValidTo = validTo;
        MaxUses = maxUses;
        return Result.Success();
    }

    public bool IsRedeemableFor(string planCode, long amountPaise, DateTimeOffset now) =>
        IsActive
        && now >= ValidFrom
        && (ValidTo is null || now <= ValidTo)
        && (MaxUses is null || UsesCount < MaxUses)
        && (ApplicablePlanCode is null || string.Equals(ApplicablePlanCode, planCode.Trim(), StringComparison.OrdinalIgnoreCase))
        && amountPaise >= MinAmountPaise;

    /// <summary>
    /// The discount in paise for a charge of <paramref name="amountPaise"/>, capped so the remaining charge is never
    /// below <see cref="MinimumChargePaise"/>.
    /// </summary>
    public long CalculateDiscount(long amountPaise)
    {
        if (amountPaise <= MinimumChargePaise)
        {
            return 0;
        }

        var raw = DiscountType == DiscountType.Percent
            ? amountPaise * DiscountValue / 100
            : DiscountValue;

        return Math.Min(raw, amountPaise - MinimumChargePaise);
    }
}
