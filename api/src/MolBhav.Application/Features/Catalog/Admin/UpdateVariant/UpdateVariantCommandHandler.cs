using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateVariant;

internal sealed class UpdateVariantCommandHandler(IProductRepository products, ILanguageContext languageContext)
    : ICommandHandler<UpdateVariantCommand>
{
    public async Task<Result> Handle(UpdateVariantCommand request, CancellationToken cancellationToken)
    {
        var product = await products.GetByIdAsync(request.ProductId, cancellationToken);
        if (product is null)
        {
            return Error.NotFound("Product.NotFound", "Product not found.");
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return translations.Error;
        }

        return product.UpdateVariant(request.VariantId, request.DisplayOrder, request.IsActive!.Value, translations.Value);
    }
}
