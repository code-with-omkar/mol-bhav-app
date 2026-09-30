using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Pricing;

public static class PricingRules
{
    public const int SourceCodeMaxLength = 40;
    public const int SourceNameMaxLength = 100;
    public const int PriceScale = 2;
    public const int QuantityScale = 2;

    public static Result<string> ValidateSourceName(string? name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return Error.Validation("PriceSource.NameRequired", "Source name is required.");
        }

        var trimmed = name.Trim();
        return trimmed.Length <= SourceNameMaxLength
            ? trimmed
            : Error.Validation("PriceSource.NameTooLong", $"Source name cannot exceed {SourceNameMaxLength} characters.");
    }

    public static Result<string> ValidateSourceCode(string? code)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return Error.Validation("PriceSource.CodeRequired", "Source code is required.");
        }

        var normalised = code.Trim().ToLowerInvariant();
        return normalised.Length <= SourceCodeMaxLength
            ? normalised
            : Error.Validation("PriceSource.CodeTooLong", $"Source code cannot exceed {SourceCodeMaxLength} characters.");
    }

    /// <summary>At most 2 decimal places and non-negative.</summary>
    public static bool IsValidAmount(decimal value) => value >= 0m && decimal.Round(value, PriceScale) == value;
}
