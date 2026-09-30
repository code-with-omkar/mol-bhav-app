using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Support.Models;

namespace MolBhav.Application.Features.Support.GetMyTickets;

public sealed record GetMyTicketsQuery(int Page, int PageSize) : IQuery<PagedResult<SupportTicketSummaryResponse>>;
