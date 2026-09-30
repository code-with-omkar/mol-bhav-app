using FluentValidation;

namespace MolBhav.Application.Features.Support.Admin.UpdateTicketStatus;

internal sealed class UpdateTicketStatusCommandValidator : AbstractValidator<UpdateTicketStatusCommand>
{
    public UpdateTicketStatusCommandValidator()
    {
        RuleFor(x => x.TicketId).NotEmpty();
        RuleFor(x => x.Status).NotNull().WithMessage("status is required.");
        RuleFor(x => x.Status!.Value).IsInEnum().When(x => x.Status is not null);
    }
}
