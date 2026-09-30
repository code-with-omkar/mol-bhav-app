namespace MolBhav.Application.Features.Localization.Models;

// Admin read models: every translation included, so the admin portal can edit what it shows.

public sealed record LocalizedTextTranslationResponse(string LanguageCode, string Text);

public sealed record AdminLocalizedTextResponse(
    Guid Id,
    string Key,
    string? Description,
    IReadOnlyList<LocalizedTextTranslationResponse> Translations);
