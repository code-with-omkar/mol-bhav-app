using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.GetProducts;

/// <summary>Products of one category, optionally narrowed to a sub-category and/or a name search (any language).</summary>
public sealed record GetProductsQuery(string CategoryCode, Guid? SubCategoryId, string? Search, int Page, int PageSize)
    : IQuery<PagedResult<ProductSummaryResponse>>;
