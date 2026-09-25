using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.AddVariant;

internal sealed class AddVariantCommandHandler(IProductRepository products, ILanguageContext languageContext)
    : ICommandHandler<AddVariantCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(AddVariantCommand request, CancellationToken cancellationToken)
    {
        var product = await products.GetByIdAsync(request.ProductId, cancellationToken);
        if (product is null)
        {
            return Error.NotFound("Product.NotFound", "Product not found.");
        }

        var code = CatalogCode.Create(request.Code);
        if (code.IsFailure)
        {
            return Result.Failure<CreatedResponse>(code.Error);
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return Result.Failure<CreatedResponse>(translations.Error);
        }

        var variant = product.AddVariant(code.Value, request.DisplayOrder, translations.Value);
        return variant.IsSuccess
            ? new CreatedResponse(variant.Value.Id)
            : Result.Failure<CreatedResponse>(variant.Error);
    }
}
