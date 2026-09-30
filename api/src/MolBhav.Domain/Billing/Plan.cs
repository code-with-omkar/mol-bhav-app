using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Billing;

/// <summary>A purchasable subscription tier (BRD §23/§25: Plans/Subscriptions/Entitlements). Deactivated, never
/// deleted — subscriptions reference it.</summary>
public sealed class Plan : AggregateRoot<Guid>, IAuditableEntity
{
    public const int CodeMaxLength = 32;
    public const int NameMaxLength = 100;
    public const string DefaultCurrency = "INR";

    private Plan(Guid id, string code, string name, decimal price, string currency, BillingPeriod billingPeriod)
        : base(id)
    {
        Code = code;
        Name = name;
        Price = price;
        Currency = currency;
        BillingPeriod = billingPeriod;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Plan()
    {
        Code = string.Empty;
        Name = string.Empty;
        Currency = string.Empty;
    }

    /// <summary>Globally unique, immutable.</summary>
    public string Code { get; private set; }

    public string Name { get; private set; }

    public decimal Price { get; private set; }

    public string Currency { get; private set; }

    public BillingPeriod BillingPeriod { get; private set; }

    /// <summary>The server-side price in paise; the only amount a checkout is ever charged from.</summary>
    public long PricePaise => (long)decimal.Round(Price * 100m, MidpointRounding.AwayFromZero);

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<Plan> Create(string? code, string? name, decimal price, string? currency, BillingPeriod billingPeriod)
    {
        var codeResult = ValidateCode(code);
        if (codeResult.IsFailure)
        {
            return Result.Failure<Plan>(codeResult.Error);
        }

        var nameResult = ValidateName(name);
        if (nameResult.IsFailure)
        {
            return Result.Failure<Plan>(nameResult.Error);
        }

        if (price < 0)
        {
            return Error.Validation("Plan.InvalidPrice", "Price must not be negative.");
        }

        var normalisedCurrency = string.IsNullOrWhiteSpace(currency) ? DefaultCurrency : currency.Trim().ToUpperInvariant();
        if (normalisedCurrency.Length != 3)
        {
            return Error.Validation("Plan.InvalidCurrency", "Currency must be a 3-letter ISO-4217 code.");
        }

        return new Plan(Guid.CreateVersion7(), codeResult.Value, nameResult.Value, price, normalisedCurrency, billingPeriod);
    }

    public Result Update(string? name, decimal price, bool isActive)
    {
        var nameResult = ValidateName(name);
        if (nameResult.IsFailure)
        {
            return nameResult.Error;
        }

        if (price < 0)
        {
            return Error.Validation("Plan.InvalidPrice", "Price must not be negative.");
        }

        Name = nameResult.Value;
        Price = price;
        IsActive = isActive;
        return Result.Success();
    }

    private static Result<string> ValidateCode(string? code)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return Error.Validation("Plan.CodeRequired", "Code is required.");
        }

        var trimmed = code.Trim();
        return trimmed.Length <= CodeMaxLength
            ? trimmed
            : Error.Validation("Plan.CodeTooLong", $"Code must be at most {CodeMaxLength} characters.");
    }

    private static Result<string> ValidateName(string? name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return Error.Validation("Plan.NameRequired", "Name is required.");
        }

        var trimmed = name.Trim();
        return trimmed.Length <= NameMaxLength
            ? trimmed
            : Error.Validation("Plan.NameTooLong", $"Name must be at most {NameMaxLength} characters.");
    }
}
