using FluentValidation;
using MolBhav.Domain.Alerting;

namespace MolBhav.Application.Features.Alerting.CreateAlertRule;

internal sealed class CreateAlertRuleCommandValidator : AbstractValidator<CreateAlertRuleCommand>
{
    public CreateAlertRuleCommandValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();

        RuleFor(x => x.ThresholdType).NotNull().WithMessage("thresholdType is required.");
        RuleFor(x => x.ThresholdType!.Value).IsInEnum().When(x => x.ThresholdType is not null);

        // Which threshold field applies is decided by the type (see AlertRule.ValidateThreshold).
        RuleFor(x => x.ThresholdPercent).NotNull()
            .When(x => x.ThresholdType is { } t && AlertRule.IsPercentType(t))
            .WithMessage("thresholdPercent is required for a PriceDrop/PriceSpike rule.");
        RuleFor(x => x.ThresholdPercent!.Value).InclusiveBetween(AlertRule.MinThresholdPercent, AlertRule.MaxThresholdPercent)
            .When(x => x.ThresholdPercent is not null);

        RuleFor(x => x.ThresholdPrice).NotNull()
            .When(x => x.ThresholdType is { } t && !AlertRule.IsPercentType(t))
            .WithMessage("thresholdPrice is required for a PriceBelow/PriceAbove rule.");
        RuleFor(x => x.ThresholdPrice!.Value).InclusiveBetween(AlertRule.MinThresholdPrice, AlertRule.MaxThresholdPrice)
            .When(x => x.ThresholdPrice is not null);

        RuleFor(x => x.MandiId).Empty().When(x => x.LocationKind is null).WithMessage("A product-wide rule must not set a mandi.");
        RuleFor(x => x.SupplierId).Empty().When(x => x.LocationKind is null).WithMessage("A product-wide rule must not set a supplier.");

        RuleFor(x => x.MandiId).NotEmpty().When(x => x.LocationKind == Domain.Pricing.LocationKind.Mandi)
            .WithMessage("A mandi-scoped rule requires a mandi id.");
        RuleFor(x => x.SupplierId).NotEmpty().When(x => x.LocationKind == Domain.Pricing.LocationKind.Supplier)
            .WithMessage("A supplier-scoped rule requires a supplier id.");
    }
}
