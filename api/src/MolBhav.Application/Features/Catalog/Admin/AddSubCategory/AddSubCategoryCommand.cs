using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.AddSubCategory;

public sealed record AddSubCategoryCommand(
    Guid CategoryId,
    string Code,
    int DisplayOrder,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand<CreatedResponse>;
