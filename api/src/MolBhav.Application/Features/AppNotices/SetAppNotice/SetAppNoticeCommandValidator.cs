using FluentValidation;
using MolBhav.Domain.AppNotices;

namespace MolBhav.Application.Features.AppNotices.SetAppNotice;

internal sealed class SetAppNoticeCommandValidator : AbstractValidator<SetAppNoticeCommand>
{
    public SetAppNoticeCommandValidator()
    {
        RuleFor(x => x.Severity).IsInEnum();
        RuleFor(x => x.Message).MaximumLength(AppNotice.MessageMaxLength);
        RuleFor(x => x.Message).NotEmpty().When(x => x.IsActive).WithMessage("Write the message users should see.");
    }
}
