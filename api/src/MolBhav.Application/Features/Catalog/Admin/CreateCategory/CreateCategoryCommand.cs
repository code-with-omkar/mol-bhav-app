using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.CreateCategory;

public sealed record CreateCategoryCommand(
    string Code,
    string? IconKey,
    int DisplayOrder,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand<CreatedResponse>;
