using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Audit.Models;

namespace MolBhav.Application.Abstractions.Audit;

/// <summary>Dapper-backed reads of the audit log.</summary>
public interface IAuditReadService
{
    /// <summary>Entries newest first; <paramref name="action"/> (exact code, e.g. <c>User.Suspend</c>) narrows them, null = all.</summary>
    Task<PagedResult<AuditEntryResponse>> GetEntriesAsync(string? action, PageRequest page, CancellationToken cancellationToken = default);
}
