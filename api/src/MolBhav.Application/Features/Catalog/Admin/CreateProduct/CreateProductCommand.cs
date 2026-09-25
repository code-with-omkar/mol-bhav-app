using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.CreateProduct;

public sealed record CreateProductCommand(
    string Code,
    Guid SubCategoryId,
    Guid DefaultUnitId,
    int DisplayOrder,
    string? ImageKey,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand<CreatedResponse>;
