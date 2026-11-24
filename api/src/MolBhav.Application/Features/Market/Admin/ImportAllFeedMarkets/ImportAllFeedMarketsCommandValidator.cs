using FluentValidation;

namespace MolBhav.Application.Features.Market.Admin.ImportAllFeedMarkets;

internal sealed class ImportAllFeedMarketsCommandValidator : AbstractValidator<ImportAllFeedMarketsCommand>
{
    public ImportAllFeedMarketsCommandValidator()
    {
        RuleFor(x => x.PriceSourceId).NotEmpty();
    }
}
