using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminProduct;

public sealed record GetAdminProductQuery(Guid ProductId) : IQuery<AdminProductResponse>;
