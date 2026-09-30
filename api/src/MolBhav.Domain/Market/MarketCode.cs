using System.Text.RegularExpressions;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Market;

/// <summary>Stable, language-neutral identifier for mandis and suppliers (BRD §19/§20): <c>apmc-pune</c>, <c>hub-nagpur-01</c>. Ingestion adapters map source location names onto it.</summary>
public sealed partial record MarketCode
{
    public const int MaxLength = 40;

    private MarketCode(string value) => Value = value;

    public string Value { get; private init; }

    public static Result<MarketCode> Create(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return Error.Validation("MarketCode.Empty", "Code is required.");
        }

        var normalised = input.Trim().ToLowerInvariant();

        if (normalised.Length > MaxLength)
        {
            return Error.Validation("MarketCode.TooLong", $"Code cannot exceed {MaxLength} characters.");
        }

        return CodePattern().IsMatch(normalised)
            ? new MarketCode(normalised)
            : Error.Validation("MarketCode.Invalid", "Code must start with a letter and contain only lowercase letters, digits and hyphens.");
    }

    public override string ToString() => Value;

    [GeneratedRegex("^[a-z][a-z0-9-]{0,39}$", RegexOptions.CultureInvariant, matchTimeoutMilliseconds: 100)]
    private static partial Regex CodePattern();
}
