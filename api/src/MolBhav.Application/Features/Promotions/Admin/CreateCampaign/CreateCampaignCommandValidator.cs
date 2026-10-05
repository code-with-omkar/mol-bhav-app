using FluentValidation;

namespace MolBhav.Application.Features.Promotions.Admin.CreateCampaign;

internal sealed class CreateCampaignCommandValidator : AbstractValidator<CreateCampaignCommand>
{
    public CreateCampaignCommandValidator()
    {
        RuleFor(x => x.AdvertiserId).NotEmpty();
        // `!` only narrows the type for SetValidator; NotNull still reports a missing input (and child rules skip null).
        RuleFor(x => x.Input!).NotNull().SetValidator(new CampaignInputValidator());
    }
}
