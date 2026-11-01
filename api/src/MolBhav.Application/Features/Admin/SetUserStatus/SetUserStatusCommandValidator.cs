using FluentValidation;

namespace MolBhav.Application.Features.Admin.SetUserStatus;

internal sealed class SetUserStatusCommandValidator : AbstractValidator<SetUserStatusCommand>
{
    public SetUserStatusCommandValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.Action).IsInEnum();
    }
}
