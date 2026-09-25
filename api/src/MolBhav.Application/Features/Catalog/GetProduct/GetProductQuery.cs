using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.GetProduct;

/// <summary>Product detail header (name, unit, variants) — shared by the comparison, trends and opportunity screens.</summary>
public sealed record GetProductQuery(Guid ProductId) : IQuery<ProductDetailResponse>;
