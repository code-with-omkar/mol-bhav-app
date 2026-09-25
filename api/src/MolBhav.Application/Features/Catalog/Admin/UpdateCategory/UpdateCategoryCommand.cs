using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateCategory;

/// <summary>Full replacement of editable fields. The code is immutable (other modules reference it).</summary>
public sealed record UpdateCategoryCommand(
    Guid CategoryId,
    string? IconKey,
    int DisplayOrder,
    bool? IsActive,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand;
