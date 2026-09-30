using FluentValidation;

namespace MolBhav.Application.Features.Notification.RegisterDeviceToken;

internal sealed class RegisterDeviceTokenCommandValidator : AbstractValidator<RegisterDeviceTokenCommand>
{
    public RegisterDeviceTokenCommandValidator()
    {
        RuleFor(x => x.Token)
            .NotEmpty()
            .MaximumLength(500);
    }
}
