using MolBhav.Domain.Support;

namespace MolBhav.Api.Contracts.Support;

/// <summary>A ticket is always raised with its opening message — there is no empty ticket.</summary>
public sealed record CreateTicketRequest(SupportTicketCategory? Category, string? Subject, string? Message);

/// <summary>One more turn in the thread, from the owner or (on the admin route) from support.</summary>
public sealed record AddTicketMessageRequest(string? Message);

/// <summary>Admin-only. <c>Closed</c> is terminal, so nothing may be set on an already-closed ticket.</summary>
public sealed record UpdateTicketStatusRequest(SupportTicketStatus? Status);
