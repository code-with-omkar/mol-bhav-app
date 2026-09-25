using System.Text.RegularExpressions;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.SharedKernel;

/// <summary>
/// Code of a procurement category (e.g. <c>agriculture</c>, <c>construction</c>) — the key other modules use to reference
/// a catalog category. The value object validates shape only; which categories exist and are active is catalog data
/// (admin-managed, no fixed whitelist here), checked via <c>IProcurementCategoryLookup</c> and enforced by FKs.
/// </summary>
public sealed partial record ProcurementCategoryCode
{
    public const int MaxLength = 40;

    private ProcurementCategoryCode(string value) => Value = value;

    public string Value { get; private init; }

    public static Result<ProcurementCategoryCode> Create(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return Error.Validation("ProcurementCategoryCode.Empty", "Category code is required.");
        }

        var normalised = input.Trim().ToLowerInvariant();

        if (normalised.Length > MaxLength)
        {
            return Error.Validation("ProcurementCategoryCode.TooLong", $"Category code cannot exceed {MaxLength} characters.");
        }

        return CodePattern().IsMatch(normalised)
            ? new ProcurementCategoryCode(normalised)
            : Error.Validation("ProcurementCategoryCode.Invalid", "Category code must start with a letter and contain only lowercase letters, digits and hyphens.");
    }

    public override string ToString() => Value;

    [GeneratedRegex("^[a-z][a-z0-9-]{0,39}$", RegexOptions.CultureInvariant, matchTimeoutMilliseconds: 100)]
    private static partial Regex CodePattern();
}
