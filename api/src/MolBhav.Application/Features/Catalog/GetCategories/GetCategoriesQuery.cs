using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.GetCategories;

/// <summary>Select Category screen (onboarding) and category tabs: active categories with their active sub-categories, localized.</summary>
public sealed record GetCategoriesQuery : IQuery<IReadOnlyList<CategoryResponse>>;
