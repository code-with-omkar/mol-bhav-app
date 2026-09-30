using FluentValidation;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.AddTicketMessage;

internal sealed class AddTicketMessageCommandValidator : AbstractValidator<AddTicketMessageCommand>
{
    public AddTicketMessageCommandValidator()
    {
        RuleFor(x => x.TicketId).NotEmpty();

        RuleFor(x => x.Message).NotEmpty().WithMessage("message is required.");
        RuleFor(x => x.Message!.Trim().Length)
            .InclusiveBetween(SupportTicketMessage.BodyMinLength, SupportTicketMessage.BodyMaxLength)
            .WithMessage($"message must be between {SupportTicketMessage.BodyMinLength} and {SupportTicketMessage.BodyMaxLength} characters.")
            .OverridePropertyName(nameof(AddTicketMessageCommand.Message))
            .When(x => !string.IsNullOrWhiteSpace(x.Message));
    }
}
