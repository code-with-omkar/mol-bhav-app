using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminCategories;

/// <summary>Full category tree for the admin portal: inactive items and every translation included.</summary>
public sealed record GetAdminCategoriesQuery : IQuery<IReadOnlyList<AdminCategoryResponse>>;
