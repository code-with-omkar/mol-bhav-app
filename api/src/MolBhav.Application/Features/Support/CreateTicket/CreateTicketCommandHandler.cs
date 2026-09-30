using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.CreateTicket;

internal sealed class CreateTicketCommandHandler(
    ISupportTicketRepository tickets,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : ICommandHandler<CreateTicketCommand, CreatedResponse>
{
    public Task<Result<CreatedResponse>> Handle(CreateTicketCommand request, CancellationToken cancellationToken)
    {
        var ticket = SupportTicket.Create(
            currentUser.GetRequiredUserId(),
            request.Category!.Value,
            request.Subject,
            request.Message,
            timeProvider.GetUtcNow());

        if (ticket.IsFailure)
        {
            return Task.FromResult(Result.Failure<CreatedResponse>(ticket.Error));
        }

        tickets.Add(ticket.Value);
        return Task.FromResult(Result.Success(new CreatedResponse(ticket.Value.Id)));
    }
}
