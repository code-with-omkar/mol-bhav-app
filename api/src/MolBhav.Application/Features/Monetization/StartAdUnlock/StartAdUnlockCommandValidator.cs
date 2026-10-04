using FluentValidation;

namespace MolBhav.Application.Features.Monetization.StartAdUnlock;

internal sealed class StartAdUnlockCommandValidator : AbstractValidator<StartAdUnlockCommand>
{
    public StartAdUnlockCommandValidator() => RuleFor(x => x.Feature).NotNull().IsInEnum();
}
