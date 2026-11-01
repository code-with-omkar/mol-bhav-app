using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Abstractions.Ingestion;

/// <summary>Dapper-backed admin reads for ingestion monitoring (BRD §22: "Monitor ingestion jobs and failures").</summary>
public interface IIngestionReadService
{
    Task<PagedResult<AdminIngestionJobResponse>> GetAdminJobsAsync(AdminIngestionJobFilter filter, CancellationToken cancellationToken = default);

    /// <summary>Null when the job does not exist.</summary>
    Task<AdminIngestionJobResponse?> GetAdminJobAsync(Guid jobId, CancellationToken cancellationToken = default);

    Task<PagedResult<AdminIngestionErrorResponse>> GetAdminJobErrorsAsync(Guid jobId, PageRequest page, CancellationToken cancellationToken = default);

    /// <summary>Every price source with its schedule (if any) and its most recent job (if any).</summary>
    Task<IReadOnlyList<AdminIngestionScheduleResponse>> GetAdminSchedulesAsync(AdminIngestionScheduleFilter filter, CancellationToken cancellationToken = default);

    /// <summary>
    /// How each automatically refreshed feed (an active source with an enabled schedule) is doing, from its adapter runs —
    /// manual file uploads are ignored. Feeds that nobody schedules are not expected to update, so they are not listed.
    /// </summary>
    Task<IReadOnlyList<FeedHealth>> GetScheduledFeedHealthAsync(CancellationToken cancellationToken = default);
}

/// <summary>
/// One scheduled feed's track record: when an adapter run last got data in (<see cref="IngestionJobStatus.Succeeded"/> or
/// <see cref="IngestionJobStatus.PartiallySucceeded"/>), and how the most recent adapter run ended.
/// </summary>
public sealed record FeedHealth(
    Guid PriceSourceId,
    string PriceSourceCode,
    DateTimeOffset? LastSuccessAtUtc,
    IngestionJobStatus? LastAttemptStatus,
    DateTimeOffset? LastAttemptAtUtc);

public sealed record AdminIngestionJobFilter(Guid? PriceSourceId, IngestionJobStatus? Status, PageRequest Page);

/// <summary>Schedules list filter: <paramref name="CategoryCode"/> null = every category; names localized per <paramref name="Language"/>.</summary>
public sealed record AdminIngestionScheduleFilter(string? CategoryCode, LanguagePreference Language);
