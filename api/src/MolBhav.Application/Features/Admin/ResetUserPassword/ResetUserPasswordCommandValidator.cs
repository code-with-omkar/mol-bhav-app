using FluentValidation;

namespace MolBhav.Application.Features.Admin.ResetUserPassword;

internal sealed class ResetUserPasswordCommandValidator : AbstractValidator<ResetUserPasswordCommand>
{
    public ResetUserPasswordCommandValidator()
    {
        RuleFor(x => x.UserId).NotEmpty();
    }
}
