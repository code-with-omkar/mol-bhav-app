using FluentValidation;

namespace MolBhav.Application.Features.Identity.PasswordLogin;

/// <summary>Structural checks only; the policy applies to new passwords, never to login attempts.</summary>
internal sealed class LoginWithPasswordCommandValidator : AbstractValidator<LoginWithPasswordCommand>
{
    public LoginWithPasswordCommandValidator()
    {
        RuleFor(x => x.PhoneNumber)
            .NotEmpty()
            .MaximumLength(20);

        RuleFor(x => x.Password)
            .NotEmpty()
            .MaximumLength(PasswordPolicy.MaxLength);
    }
}
