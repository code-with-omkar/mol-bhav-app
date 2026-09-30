using FluentValidation;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.Admin.AddAdminTicketMessage;

internal sealed class AddAdminTicketMessageCommandValidator : AbstractValidator<AddAdminTicketMessageCommand>
{
    public AddAdminTicketMessageCommandValidator()
    {
        RuleFor(x => x.TicketId).NotEmpty();

        RuleFor(x => x.Message).NotEmpty().WithMessage("message is required.");
        RuleFor(x => x.Message!.Trim().Length)
            .InclusiveBetween(SupportTicketMessage.BodyMinLength, SupportTicketMessage.BodyMaxLength)
            .WithMessage($"message must be between {SupportTicketMessage.BodyMinLength} and {SupportTicketMessage.BodyMaxLength} characters.")
            .OverridePropertyName(nameof(AddAdminTicketMessageCommand.Message))
            .When(x => !string.IsNullOrWhiteSpace(x.Message));
    }
}
