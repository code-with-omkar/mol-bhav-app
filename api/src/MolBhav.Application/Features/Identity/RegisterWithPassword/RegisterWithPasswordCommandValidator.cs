using FluentValidation;

namespace MolBhav.Application.Features.Identity.RegisterWithPassword;

internal sealed class RegisterWithPasswordCommandValidator : AbstractValidator<RegisterWithPasswordCommand>
{
    public RegisterWithPasswordCommandValidator()
    {
        RuleFor(x => x.PhoneNumber)
            .NotEmpty()
            .MaximumLength(20);

        RuleFor(x => x.Password).NewPassword();
    }
}
