using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminProducts;

public sealed record GetAdminProductsQuery(
    string? CategoryCode,
    Guid? SubCategoryId,
    string? Search,
    bool? IsActive,
    int Page,
    int PageSize) : IQuery<PagedResult<AdminProductSummaryResponse>>;
