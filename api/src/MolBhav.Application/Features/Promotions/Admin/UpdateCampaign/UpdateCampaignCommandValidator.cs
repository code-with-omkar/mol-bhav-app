using FluentValidation;

namespace MolBhav.Application.Features.Promotions.Admin.UpdateCampaign;

internal sealed class UpdateCampaignCommandValidator : AbstractValidator<UpdateCampaignCommand>
{
    public UpdateCampaignCommandValidator() =>
        RuleFor(x => x.Input).NotNull().SetValidator(new CampaignInputValidator());
}
