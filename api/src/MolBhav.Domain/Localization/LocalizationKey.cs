using System.Text.RegularExpressions;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Localization;

/// <summary>
/// Stable, dot-namespaced identifier for a piece of data-driven terminology (BRD §8/§18: "localization stored as
/// data/configuration rather than hard-coded"): <c>alerts.price_drop.title</c>, <c>reports.weekly_summary.subject</c>.
/// Other modules (Alerting, Notification, Reporting) look strings up by this key; it is immutable once created.
/// </summary>
public sealed partial record LocalizationKey
{
    public const int MaxLength = 150;

    private LocalizationKey(string value) => Value = value;

    public string Value { get; private init; }

    public static Result<LocalizationKey> Create(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return Error.Validation("LocalizationKey.Empty", "Key is required.");
        }

        var normalised = input.Trim().ToLowerInvariant();

        if (normalised.Length > MaxLength)
        {
            return Error.Validation("LocalizationKey.TooLong", $"Key cannot exceed {MaxLength} characters.");
        }

        return KeyPattern().IsMatch(normalised)
            ? new LocalizationKey(normalised)
            : Error.Validation(
                "LocalizationKey.Invalid",
                "Key must be lowercase, dot-separated segments starting with a letter (e.g. 'alerts.price_drop.title').");
    }

    public override string ToString() => Value;

    [GeneratedRegex("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)*$", RegexOptions.CultureInvariant, matchTimeoutMilliseconds: 100)]
    private static partial Regex KeyPattern();
}
