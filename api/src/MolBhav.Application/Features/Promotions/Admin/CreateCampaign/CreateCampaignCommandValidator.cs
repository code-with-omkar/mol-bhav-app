using FluentValidation;

namespace MolBhav.Application.Features.Promotions.Admin.CreateCampaign;

internal sealed class CreateCampaignCommandValidator : AbstractValidator<CreateCampaignCommand>
{
    public CreateCampaignCommandValidator()
    {
        RuleFor(x => x.AdvertiserId).NotEmpty();
        RuleFor(x => x.Input).NotNull().SetValidator(new CampaignInputValidator());
    }
}
