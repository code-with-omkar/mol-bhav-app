using MolBhav.Application.Features.Localization.Models;

namespace MolBhav.Api.Contracts.Localization;

// Admin portal request bodies. PUTs are full replacements.
// translations: [{ "languageCode": "en", "text": "Price drop alert" }, { "languageCode": "mr", "text": "किंमत घसरण सूचना" }]
// English is required; only enabled languages are accepted.

public sealed record CreateLocalizedTextRequest(
    string? Key,
    string? Description,
    IReadOnlyCollection<LocalizedTextTranslationInput>? Translations);

public sealed record UpdateLocalizedTextRequest(
    string? Description,
    IReadOnlyCollection<LocalizedTextTranslationInput>? Translations);
