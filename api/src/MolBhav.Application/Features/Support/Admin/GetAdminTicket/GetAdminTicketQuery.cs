using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Support.Models;

namespace MolBhav.Application.Features.Support.Admin.GetAdminTicket;

public sealed record GetAdminTicketQuery(Guid TicketId) : IQuery<SupportTicketResponse>;
