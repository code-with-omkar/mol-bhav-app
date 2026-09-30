using FluentValidation;
using MolBhav.Domain.Alerting;

namespace MolBhav.Application.Features.Alerting.UpdateAlertRule;

internal sealed class UpdateAlertRuleCommandValidator : AbstractValidator<UpdateAlertRuleCommand>
{
    public UpdateAlertRuleCommandValidator()
    {
        RuleFor(x => x.AlertRuleId).NotEmpty();

        // Exactly one threshold is sent; which one the rule's own type requires is checked in AlertRule.Update.
        RuleFor(x => x.ThresholdPercent)
            .Must((command, _) => command.ThresholdPercent is not null ^ command.ThresholdPrice is not null)
            .WithMessage("Send exactly one of thresholdPercent or thresholdPrice.");
        RuleFor(x => x.ThresholdPercent!.Value).InclusiveBetween(AlertRule.MinThresholdPercent, AlertRule.MaxThresholdPercent)
            .When(x => x.ThresholdPercent is not null);
        RuleFor(x => x.ThresholdPrice!.Value).InclusiveBetween(AlertRule.MinThresholdPrice, AlertRule.MaxThresholdPrice)
            .When(x => x.ThresholdPrice is not null);

        RuleFor(x => x.IsActive).NotNull().WithMessage("isActive is required.");
    }
}
