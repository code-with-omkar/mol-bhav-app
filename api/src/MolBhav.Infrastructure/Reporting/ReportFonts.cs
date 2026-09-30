using QuestPDF.Drawing;
using QuestPDF.Infrastructure;

namespace MolBhav.Infrastructure.Reporting;

/// <summary>
/// One-time QuestPDF setup: Community licence and the embedded Noto fonts. Only embedded fonts are used, so PDFs
/// render the same on a developer machine and a bare Linux container.
/// </summary>
internal static class ReportFonts
{
    /// <summary>Latin first (digits, ₹, punctuation), then each Indic script; QuestPDF falls back glyph by glyph.</summary>
    public static readonly string[] Families =
    [
        "Noto Sans", "Noto Sans Devanagari", "Noto Sans Gujarati", "Noto Sans Tamil", "Noto Sans Telugu", "Noto Sans Kannada",
    ];

    private static readonly Lazy<bool> Registered = new(Register, LazyThreadSafetyMode.ExecutionAndPublication);

    public static void EnsureRegistered() => _ = Registered.Value;

    private static bool Register()
    {
        QuestPDF.Settings.License = LicenseType.Community;
        QuestPDF.Settings.UseSystemFonts = false;

        var assembly = typeof(ReportFonts).Assembly;
        foreach (var name in assembly.GetManifestResourceNames().Where(n => n.StartsWith("MolBhav.Fonts.", StringComparison.Ordinal)))
        {
            using var stream = assembly.GetManifestResourceStream(name)
                ?? throw new InvalidOperationException($"Embedded font '{name}' is missing.");
            FontManager.RegisterFontFromStream(stream);
        }

        return true;
    }
}
