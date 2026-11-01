using FluentValidation;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.ImportFeedMarkets;

internal sealed class ImportFeedMarketsCommandValidator : AbstractValidator<ImportFeedMarketsCommand>
{
    /// <summary>One request adds at most this many markets, so a single save stays small.</summary>
    public const int MaxMarkets = 200;

    public ImportFeedMarketsCommandValidator()
    {
        RuleFor(x => x.PriceSourceId).NotEmpty();
        RuleFor(x => x.State).NotEmpty().MaximumLength(MarketRules.StateNameMaxLength);
        RuleFor(x => x.Markets).NotEmpty().WithMessage("Choose at least one market.");
        RuleFor(x => x.Markets!.Count).LessThanOrEqualTo(MaxMarkets)
            .When(x => x.Markets is not null)
            .WithMessage($"Add at most {MaxMarkets} markets at a time.");
        RuleForEach(x => x.Markets).NotEmpty().MaximumLength(MarketRules.NameMaxLength);
    }
}
