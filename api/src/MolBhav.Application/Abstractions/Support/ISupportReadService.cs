using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Abstractions.Support;

/// <summary>Dapper-backed reads for the app's ticket list/thread and the admin support queue.</summary>
public interface ISupportReadService
{
    Task<PagedResult<SupportTicketSummaryResponse>> GetMyTicketsAsync(Guid userId, PageRequest page, CancellationToken cancellationToken = default);

    /// <summary>
    /// The ticket with its full message thread. <paramref name="userId"/> scopes it to the owner; pass <c>null</c>
    /// for the admin read, where any ticket is visible.
    /// </summary>
    Task<SupportTicketResponse?> GetTicketAsync(Guid ticketId, Guid? userId, CancellationToken cancellationToken = default);

    Task<PagedResult<AdminSupportTicketResponse>> GetAdminTicketsAsync(AdminSupportTicketFilter filter, CancellationToken cancellationToken = default);
}

/// <summary><paramref name="Search"/> matches the subject, case-insensitively.</summary>
public sealed record AdminSupportTicketFilter(
    SupportTicketStatus? Status,
    SupportTicketCategory? Category,
    string? Search,
    PageRequest Page);
