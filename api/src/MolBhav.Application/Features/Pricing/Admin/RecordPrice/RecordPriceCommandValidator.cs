using FluentValidation;

namespace MolBhav.Application.Features.Pricing.Admin.RecordPrice;

internal sealed class RecordPriceCommandValidator : AbstractValidator<RecordPriceCommand>
{
    public RecordPriceCommandValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();
        RuleFor(x => x.UnitId).NotEmpty();
        RuleFor(x => x.LocationKind).NotNull().IsInEnum();
        RuleFor(x => x.PriceSourceId).NotEmpty();
        RuleFor(x => x.ModalPrice).GreaterThanOrEqualTo(0m);
        RuleFor(x => x.RecordDate).NotEmpty();
    }
}
