using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.AddVariant;

public sealed record AddVariantCommand(
    Guid ProductId,
    string Code,
    int DisplayOrder,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand<CreatedResponse>;
