namespace MolBhav.Application.Features.Localization.Models;

/// <summary>One language's text as submitted by the admin portal.</summary>
public sealed record LocalizedTextTranslationInput(string? LanguageCode, string? Text);
