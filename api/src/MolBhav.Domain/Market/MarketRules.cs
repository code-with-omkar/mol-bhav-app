using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Market;

/// <summary>Rules shared by location/market entities (state, district, mandi, supplier names are plain strings — no per-language translation yet).</summary>
public static class MarketRules
{
    public const int StateNameMaxLength = 100;
    public const int StateCodeMaxLength = 10;
    public const int DistrictNameMaxLength = 100;
    public const int NameMaxLength = 150;
    public const int ContactPhoneMaxLength = 20;

    public static Result<string> ValidateName(string? name, int maxLength, string errorCode, string label)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return Error.Validation($"{errorCode}.NameRequired", $"{label} name is required.");
        }

        var trimmed = name.Trim();
        return trimmed.Length <= maxLength
            ? trimmed
            : Error.Validation($"{errorCode}.NameTooLong", $"{label} name cannot exceed {maxLength} characters.");
    }
}
