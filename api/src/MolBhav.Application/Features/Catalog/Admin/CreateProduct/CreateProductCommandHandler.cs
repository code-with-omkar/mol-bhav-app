using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.CreateProduct;

internal sealed class CreateProductCommandHandler(
    IProductRepository products,
    IProcurementCategoryRepository categories,
    IUnitOfMeasureRepository units,
    ILanguageContext languageContext)
    : ICommandHandler<CreateProductCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateProductCommand request, CancellationToken cancellationToken)
    {
        var code = CatalogCode.Create(request.Code);
        if (code.IsFailure)
        {
            return Result.Failure<CreatedResponse>(code.Error);
        }

        if (await products.CodeExistsAsync(code.Value, cancellationToken))
        {
            return Error.Conflict("Product.CodeTaken", $"Product '{code.Value.Value}' already exists.");
        }

        var references = await ProductReferences.CheckAsync(categories, units, request.SubCategoryId, request.DefaultUnitId, cancellationToken);
        if (references.IsFailure)
        {
            return Result.Failure<CreatedResponse>(references.Error);
        }

        var translations = CatalogTranslationMapper.ToDomain(request.Translations, languageContext.SupportedLanguages);
        if (translations.IsFailure)
        {
            return Result.Failure<CreatedResponse>(translations.Error);
        }

        var product = Product.Create(
            code.Value,
            request.SubCategoryId,
            request.DefaultUnitId,
            request.DisplayOrder,
            request.ImageKey,
            translations.Value);

        if (product.IsFailure)
        {
            return Result.Failure<CreatedResponse>(product.Error);
        }

        products.Add(product.Value);
        return new CreatedResponse(product.Value.Id);
    }
}
