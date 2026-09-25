namespace MolBhav.Application.Features.Catalog.Models;

/// <summary>One language's text as submitted by the admin portal.</summary>
public sealed record TranslationInput(string? LanguageCode, string? Name, string? Description);
