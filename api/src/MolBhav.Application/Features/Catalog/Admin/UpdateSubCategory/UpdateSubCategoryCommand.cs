using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateSubCategory;

public sealed record UpdateSubCategoryCommand(
    Guid CategoryId,
    Guid SubCategoryId,
    int DisplayOrder,
    bool? IsActive,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand;
