using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Localization.Models;

namespace MolBhav.Application.Features.Localization.Admin.UpdateLocalizedText;

public sealed record UpdateLocalizedTextCommand(
    Guid LocalizedTextId,
    string? Description,
    IReadOnlyCollection<LocalizedTextTranslationInput> Translations) : ICommand;
