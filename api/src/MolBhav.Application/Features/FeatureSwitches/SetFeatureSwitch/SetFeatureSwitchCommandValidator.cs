using FluentValidation;

namespace MolBhav.Application.Features.FeatureSwitches.SetFeatureSwitch;

internal sealed class SetFeatureSwitchCommandValidator : AbstractValidator<SetFeatureSwitchCommand>
{
    public SetFeatureSwitchCommandValidator()
    {
        RuleFor(x => x.Feature).IsInEnum();
    }
}
