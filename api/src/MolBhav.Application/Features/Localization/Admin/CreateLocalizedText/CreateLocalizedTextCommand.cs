using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Localization.Models;

namespace MolBhav.Application.Features.Localization.Admin.CreateLocalizedText;

public sealed record CreateLocalizedTextCommand(
    string Key,
    string? Description,
    IReadOnlyCollection<LocalizedTextTranslationInput> Translations) : ICommand<CreatedResponse>;
