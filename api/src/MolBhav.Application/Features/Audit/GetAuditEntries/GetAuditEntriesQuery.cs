using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Audit.Models;

namespace MolBhav.Application.Features.Audit.GetAuditEntries;

/// <summary>The audit log, newest first, optionally only one kind of action.</summary>
public sealed record GetAuditEntriesQuery(string? Action, int Page, int PageSize) : IQuery<PagedResult<AuditEntryResponse>>;
