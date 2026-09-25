using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.GetProduct;

internal sealed class GetProductQueryHandler(ICatalogReadService readService, ILanguageContext languageContext)
    : IQueryHandler<GetProductQuery, ProductDetailResponse>
{
    public async Task<Result<ProductDetailResponse>> Handle(GetProductQuery request, CancellationToken cancellationToken)
    {
        var product = await readService.GetProductAsync(request.ProductId, CatalogLanguage.From(languageContext), cancellationToken);
        return Result.FromNullable(product, Error.NotFound("Product.NotFound", "Product not found."));
    }
}
