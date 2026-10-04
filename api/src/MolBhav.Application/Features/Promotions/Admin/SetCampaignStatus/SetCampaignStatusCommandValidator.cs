using FluentValidation;

namespace MolBhav.Application.Features.Promotions.Admin.SetCampaignStatus;

internal sealed class SetCampaignStatusCommandValidator : AbstractValidator<SetCampaignStatusCommand>
{
    public SetCampaignStatusCommandValidator() => RuleFor(x => x.Action).NotNull().IsInEnum();
}
