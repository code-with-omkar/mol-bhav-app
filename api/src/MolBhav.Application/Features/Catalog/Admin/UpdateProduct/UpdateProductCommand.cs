using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateProduct;

/// <summary>Full replacement of editable fields. The code is immutable (ingestion mappings reference it).</summary>
public sealed record UpdateProductCommand(
    Guid ProductId,
    Guid SubCategoryId,
    Guid DefaultUnitId,
    int DisplayOrder,
    bool? IsActive,
    string? ImageKey,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand;
