using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.Admin.GetAdminTickets;

public sealed record GetAdminTicketsQuery(
    SupportTicketStatus? Status,
    SupportTicketCategory? Category,
    string? Search,
    int Page,
    int PageSize) : IQuery<PagedResult<AdminSupportTicketResponse>>;
