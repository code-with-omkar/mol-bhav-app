using System.Globalization;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.SharedKernel;

/// <summary>
/// Monetary amount with ISO-4217 currency. Prices are INR today; the currency is kept explicit
/// so arithmetic across currencies is rejected instead of silently producing wrong numbers.
/// </summary>
public sealed record Money
{
    public const string DefaultCurrency = "INR";

    /// <summary>Storage scale: 4 decimals keeps per-kg prices derived from per-quintal prices exact enough.</summary>
    public const int Scale = 4;

    private Money(decimal amount, string currency)
    {
        Amount = amount;
        Currency = currency;
    }

    public decimal Amount { get; private init; }

    public string Currency { get; private init; }

    public static Money Zero(string currency = DefaultCurrency) => new(0m, NormaliseCurrency(currency));

    public static Result<Money> Create(decimal amount, string currency = DefaultCurrency)
    {
        if (amount < 0m)
        {
            return Error.Validation("Money.Negative", "Amount cannot be negative.");
        }

        if (string.IsNullOrWhiteSpace(currency) || currency.Trim().Length != 3 || !currency.Trim().All(char.IsAsciiLetter))
        {
            return Error.Validation("Money.InvalidCurrency", "Currency must be a 3-letter ISO-4217 code.");
        }

        return new Money(decimal.Round(amount, Scale, MidpointRounding.ToEven), NormaliseCurrency(currency));
    }

    public Money Add(Money other)
    {
        EnsureSameCurrency(other);
        return new Money(Amount + other.Amount, Currency);
    }

    /// <summary>Signed difference (this − other). May be negative, so it is returned as a raw decimal, not <see cref="Money"/>.</summary>
    public decimal DifferenceFrom(Money other)
    {
        EnsureSameCurrency(other);
        return Amount - other.Amount;
    }

    public Money Multiply(decimal factor)
    {
        if (factor < 0m)
        {
            throw new ArgumentOutOfRangeException(nameof(factor), factor, "Factor cannot be negative.");
        }

        return new Money(decimal.Round(Amount * factor, Scale, MidpointRounding.ToEven), Currency);
    }

    public override string ToString() => string.Create(CultureInfo.InvariantCulture, $"{Currency} {Amount:0.00##}");

    private static string NormaliseCurrency(string currency) => currency.Trim().ToUpperInvariant();

    private void EnsureSameCurrency(Money other)
    {
        ArgumentNullException.ThrowIfNull(other);
        if (!string.Equals(Currency, other.Currency, StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Cannot combine {Currency} with {other.Currency}.");
        }
    }
}
