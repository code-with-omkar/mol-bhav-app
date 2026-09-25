using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateProduct;

internal sealed class UpdateProductCommandHandler(
    IProductRepository products,
    IProcurementCategoryRepository categories,
    IUnitOfMeasureRepository units,
    ILanguageContext languageContext)
    : ICommandHandler<UpdateProductCommand>
{
    public async Task<Result> Handle(UpdateProductCommand request, CancellationToken cancellationToken)
    {
        var product = await products.GetByIdAsync(request.ProductId, cancellationToken);
        if (product is null)
        {
            return Error.NotFound("Product.NotFound", "Product not found.");
        }

        var references = await ProductReferences.CheckAsync(categories, units, request.SubCategoryId, request.DefaultUnitId, cancellationToken);
        if (references.IsFailure)
        {
            return references;
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return translations.Error;
        }

        return product.Update(
            request.SubCategoryId,
            request.DefaultUnitId,
            request.DisplayOrder,
            request.IsActive!.Value,
            request.ImageKey,
            translations.Value);
    }
}
