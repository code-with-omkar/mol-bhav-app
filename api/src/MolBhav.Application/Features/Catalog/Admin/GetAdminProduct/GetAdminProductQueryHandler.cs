using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminProduct;

internal sealed class GetAdminProductQueryHandler(ICatalogReadService readService)
    : IQueryHandler<GetAdminProductQuery, AdminProductResponse>
{
    public async Task<Result<AdminProductResponse>> Handle(GetAdminProductQuery request, CancellationToken cancellationToken) =>
        Result.FromNullable(
            await readService.GetAdminProductAsync(request.ProductId, cancellationToken),
            Error.NotFound("Product.NotFound", "Product not found."));
}
