using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateVariant;

public sealed record UpdateVariantCommand(
    Guid ProductId,
    Guid VariantId,
    int DisplayOrder,
    bool? IsActive,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand;
