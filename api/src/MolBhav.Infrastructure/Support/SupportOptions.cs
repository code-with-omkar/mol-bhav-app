namespace MolBhav.Infrastructure.Support;

/// <summary>
/// The support channels the Help &amp; Support screen offers, bound from the <c>Support</c> section and validated at
/// startup — a build that ships without them would give users a dead-end help screen.
/// </summary>
public sealed class SupportOptions
{
    public const string SectionName = "Support";

    /// <summary>
    /// E.164 number, written however an operator finds natural — <c>+91 90000 00000</c> and <c>919000000000</c> are
    /// both accepted. It is normalised to bare digits by <see cref="NormaliseWhatsAppNumber"/> before it reaches the
    /// app, because that is the only form <c>wa.me</c> takes.
    /// </summary>
    public string WhatsAppNumber { get; set; } = string.Empty;

    /// <summary>Dialable number for a <c>tel:</c> link; <c>+</c> and spaces are allowed.</summary>
    public string Phone { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    /// <summary>Digits only, with any leading <c>+</c> and separators stripped — what <c>wa.me/&lt;number&gt;</c> expects.</summary>
    public static string NormaliseWhatsAppNumber(string? value) =>
        value is null ? string.Empty : new string([.. value.Where(char.IsAsciiDigit)]);

    public static bool IsWhatsAppNumberValid(string? value) =>
        NormaliseWhatsAppNumber(value).Length is >= 8 and <= 15
        && value!.All(c => char.IsAsciiDigit(c) || c is '+' or ' ' or '-');

    public static bool IsPhoneValid(string? value) =>
        !string.IsNullOrWhiteSpace(value)
        && value.Count(char.IsAsciiDigit) is >= 8 and <= 15
        && value.All(c => char.IsAsciiDigit(c) || c is '+' or ' ' or '-');

    /// <summary>Deliberately shallow: a full RFC 5322 check buys nothing for a value an operator types once.</summary>
    public static bool IsEmailValid(string? value) =>
        value is { Length: <= 254 } && value.Count(c => c == '@') == 1
        && value.IndexOf('@', StringComparison.Ordinal) > 0
        && value.LastIndexOf('.') > value.IndexOf('@', StringComparison.Ordinal) + 1
        && !value.Any(char.IsWhiteSpace);
}
