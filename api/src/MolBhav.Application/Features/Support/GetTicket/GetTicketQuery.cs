using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Support.Models;

namespace MolBhav.Application.Features.Support.GetTicket;

public sealed record GetTicketQuery(Guid TicketId) : IQuery<SupportTicketResponse>;
