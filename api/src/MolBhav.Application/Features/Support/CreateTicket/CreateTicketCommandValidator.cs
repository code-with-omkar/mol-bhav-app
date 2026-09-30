using FluentValidation;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.CreateTicket;

internal sealed class CreateTicketCommandValidator : AbstractValidator<CreateTicketCommand>
{
    public CreateTicketCommandValidator()
    {
        RuleFor(x => x.Category).NotNull().WithMessage("category is required.");
        RuleFor(x => x.Category!.Value).IsInEnum().When(x => x.Category is not null);

        RuleFor(x => x.Subject).NotEmpty().WithMessage("subject is required.");
        RuleFor(x => x.Subject!.Trim().Length)
            .InclusiveBetween(SupportTicket.SubjectMinLength, SupportTicket.SubjectMaxLength)
            .WithMessage($"subject must be between {SupportTicket.SubjectMinLength} and {SupportTicket.SubjectMaxLength} characters.")
            .OverridePropertyName(nameof(CreateTicketCommand.Subject))
            .When(x => !string.IsNullOrWhiteSpace(x.Subject));

        RuleFor(x => x.Message).NotEmpty().WithMessage("message is required.");
        RuleFor(x => x.Message!.Trim().Length)
            .InclusiveBetween(SupportTicketMessage.BodyMinLength, SupportTicketMessage.BodyMaxLength)
            .WithMessage($"message must be between {SupportTicketMessage.BodyMinLength} and {SupportTicketMessage.BodyMaxLength} characters.")
            .OverridePropertyName(nameof(CreateTicketCommand.Message))
            .When(x => !string.IsNullOrWhiteSpace(x.Message));
    }
}
