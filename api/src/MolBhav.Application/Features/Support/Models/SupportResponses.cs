using MolBhav.Domain.Support;

namespace MolBhav.Application.Features.Support.Models;

/// <summary>One row of the user's ticket list. <c>LastActivityAtUtc</c> is what the list is sorted by.</summary>
public sealed record SupportTicketSummaryResponse(
    Guid Id,
    SupportTicketCategory Category,
    string Subject,
    SupportTicketStatus Status,
    int MessageCount,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset LastActivityAtUtc);

/// <summary>A ticket with its full conversation, oldest message first.</summary>
public sealed record SupportTicketResponse(
    Guid Id,
    SupportTicketCategory Category,
    string Subject,
    SupportTicketStatus Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset LastActivityAtUtc,
    IReadOnlyList<SupportTicketMessageResponse> Messages);

public sealed record SupportTicketMessageResponse(
    Guid Id,
    SupportMessageAuthorKind AuthorKind,
    string Body,
    DateTimeOffset CreatedAtUtc);

/// <summary>Admin queue row — carries the owner so the queue can be worked without opening each ticket.</summary>
public sealed record AdminSupportTicketResponse(
    Guid Id,
    Guid UserId,
    string UserPhoneNumberMasked,
    SupportTicketCategory Category,
    string Subject,
    SupportTicketStatus Status,
    int MessageCount,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset LastActivityAtUtc);

/// <summary>Contact channels for the Help &amp; Support screen (configuration-backed).</summary>
public sealed record SupportContactResponse(string WhatsAppNumber, string Phone, string Email);
