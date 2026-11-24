using FluentValidation;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Admin.ImportFeedProducts;

internal sealed class ImportFeedProductsCommandValidator : AbstractValidator<ImportFeedProductsCommand>
{
    /// <summary>One request adds at most this many products, so a single save stays small.</summary>
    public const int MaxCommodities = 200;

    public ImportFeedProductsCommandValidator()
    {
        RuleFor(x => x.PriceSourceId).NotEmpty();
        RuleFor(x => x.SubCategoryId).NotEmpty();
        RuleFor(x => x.DefaultUnitId).NotEmpty();
        RuleFor(x => x.Commodities).NotEmpty().WithMessage("Choose at least one commodity.");
        RuleFor(x => x.Commodities!.Count).LessThanOrEqualTo(MaxCommodities)
            .When(x => x.Commodities is not null)
            .WithMessage($"Add at most {MaxCommodities} commodities at a time.");
        RuleForEach(x => x.Commodities).NotEmpty().MaximumLength(CatalogTranslation.NameMaxLength);
    }
}
