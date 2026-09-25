using System.Text.RegularExpressions;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.SharedKernel;

/// <summary>
/// Indian mobile number normalised to E.164 (<c>+91XXXXXXXXXX</c>). Used as the OTP login identifier.
/// Accepts <c>9876543210</c>, <c>09876543210</c>, <c>919876543210</c>, <c>+91 98765-43210</c>.
/// </summary>
public sealed partial record PhoneNumber
{
    public const string CountryCode = "+91";
    public const int MaxLength = 13;

    private PhoneNumber(string value) => Value = value;

    public string Value { get; private init; }

    /// <summary>Last 4 digits only — safe for logs and notification copy.</summary>
    public string Masked => string.Concat("******", Value.AsSpan(Value.Length - 4));

    public static Result<PhoneNumber> Create(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return Error.Validation("PhoneNumber.Empty", "Mobile number is required.");
        }

        var digits = NonDigits().Replace(input, string.Empty);

        var national = digits.Length switch
        {
            10 => digits,
            11 when digits[0] == '0' => digits[1..],
            12 when digits.StartsWith("91", StringComparison.Ordinal) => digits[2..],
            _ => null,
        };

        if (national is null || !IndianMobile().IsMatch(national))
        {
            return Error.Validation("PhoneNumber.Invalid", "Enter a valid 10-digit Indian mobile number.");
        }

        return new PhoneNumber(CountryCode + national);
    }

    public override string ToString() => Value;

    [GeneratedRegex(@"\D", RegexOptions.CultureInvariant, matchTimeoutMilliseconds: 100)]
    private static partial Regex NonDigits();

    [GeneratedRegex("^[6-9][0-9]{9}$", RegexOptions.CultureInvariant, matchTimeoutMilliseconds: 100)]
    private static partial Regex IndianMobile();
}
