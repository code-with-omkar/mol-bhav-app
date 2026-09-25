using System.Text.RegularExpressions;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Catalog;

/// <summary>
/// Stable, language-neutral identifier for catalog items (sub-categories, products, variants, units):
/// <c>onion</c>, <c>tmt-steel</c>, <c>fe-500d</c>, <c>bag-50kg</c>. Used by ingestion adapters and deep links;
/// display names are translations, never codes. Categories use <see cref="SharedKernel.ProcurementCategoryCode"/>
/// (same shape) because other modules reference them.
/// </summary>
public sealed partial record CatalogCode
{
    public const int MaxLength = 40;

    private CatalogCode(string value) => Value = value;

    public string Value { get; private init; }

    public static Result<CatalogCode> Create(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return Error.Validation("CatalogCode.Empty", "Code is required.");
        }

        var normalised = input.Trim().ToLowerInvariant();

        if (normalised.Length > MaxLength)
        {
            return Error.Validation("CatalogCode.TooLong", $"Code cannot exceed {MaxLength} characters.");
        }

        return CodePattern().IsMatch(normalised)
            ? new CatalogCode(normalised)
            : Error.Validation("CatalogCode.Invalid", "Code must start with a letter and contain only lowercase letters, digits and hyphens.");
    }

    public override string ToString() => Value;

    [GeneratedRegex("^[a-z][a-z0-9-]{0,39}$", RegexOptions.CultureInvariant, matchTimeoutMilliseconds: 100)]
    private static partial Regex CodePattern();
}
