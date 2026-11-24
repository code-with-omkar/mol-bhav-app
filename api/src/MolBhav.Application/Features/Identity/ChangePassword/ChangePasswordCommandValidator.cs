using FluentValidation;

namespace MolBhav.Application.Features.Identity.ChangePassword;

internal sealed class ChangePasswordCommandValidator : AbstractValidator<ChangePasswordCommand>
{
    public ChangePasswordCommandValidator()
    {
        RuleFor(x => x.CurrentPassword).MaximumLength(PasswordPolicy.MaxLength);
        RuleFor(x => x.NewPassword).NewPassword();
        RuleFor(x => x.NewPassword)
            .NotEqual(x => x.CurrentPassword)
            .When(x => !string.IsNullOrEmpty(x.CurrentPassword))
            .WithErrorCode("Password.Unchanged")
            .WithMessage("Choose a password different from the current one.");
    }
}
