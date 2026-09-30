using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.CreateTicket;

public sealed record CreateTicketCommand(
    SupportTicketCategory? Category,
    string? Subject,
    string? Message) : ICommand<CreatedResponse>;
