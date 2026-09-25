using System.Text.RegularExpressions;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.SharedKernel;

/// <summary>
/// ISO-639-1 language code (e.g. <c>en</c>, <c>hi</c>, <c>mr</c>). The domain validates the format only;
/// which languages are enabled is configuration (see Localization settings), so new Indian languages need no code change.
/// </summary>
public sealed partial record LanguageCode
{
    public const int MaxLength = 2;

    public static readonly LanguageCode English = new("en");

    private LanguageCode(string value) => Value = value;

    public string Value { get; private init; }

    public static Result<LanguageCode> Create(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return Error.Validation("LanguageCode.Empty", "Language code is required.");
        }

        var normalised = input.Trim().ToLowerInvariant();

        return IsoPattern().IsMatch(normalised)
            ? new LanguageCode(normalised)
            : Error.Validation("LanguageCode.Invalid", "Language code must be a 2-letter ISO-639-1 code.");
    }

    public override string ToString() => Value;

    [GeneratedRegex("^[a-z]{2}$", RegexOptions.CultureInvariant, matchTimeoutMilliseconds: 100)]
    private static partial Regex IsoPattern();
}
