using FluentValidation;

namespace MolBhav.Application.Features.Promotions.Admin.UpdateCampaign;

internal sealed class UpdateCampaignCommandValidator : AbstractValidator<UpdateCampaignCommand>
{
    public UpdateCampaignCommandValidator() =>
        // `!` only narrows the type for SetValidator; NotNull still reports a missing input (and child rules skip null).
        RuleFor(x => x.Input!).NotNull().SetValidator(new CampaignInputValidator());
}
