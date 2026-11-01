using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Pricing.GetPriceDataStatus;

/// <summary>
/// Prices are "delayed" when any scheduled feed has not brought data in for <see cref="StaleAfter"/>, or when its latest
/// run failed and nothing has got through for <see cref="FailureGrace"/> (so one failed 06:00 pull shows up the same
/// morning rather than a day later, but a failure right after a good pull stays quiet while the retry catches up).
/// A feed that has never succeeded counts as delayed. With no scheduled feeds there is nothing to be late, so no banner.
/// </summary>
internal sealed class GetPriceDataStatusQueryHandler(IIngestionReadService readService, TimeProvider timeProvider)
    : IQueryHandler<GetPriceDataStatusQuery, PriceDataStatusResponse>
{
    /// <summary>A daily feed plus a buffer for a late or retried run.</summary>
    public static readonly TimeSpan StaleAfter = TimeSpan.FromHours(30);

    public static readonly TimeSpan FailureGrace = TimeSpan.FromHours(6);

    public async Task<Result<PriceDataStatusResponse>> Handle(GetPriceDataStatusQuery request, CancellationToken cancellationToken)
    {
        var feeds = await readService.GetScheduledFeedHealthAsync(cancellationToken);
        var now = timeProvider.GetUtcNow();

        var isDelayed = feeds.Any(f => IsDelayed(f, now));
        var lastUpdated = feeds.Max(f => f.LastSuccessAtUtc);

        return new PriceDataStatusResponse(isDelayed, lastUpdated);
    }

    /// <summary>Also used by the admin dashboard, so both always agree on what "delayed" means.</summary>
    internal static bool IsDelayed(FeedHealth feed, DateTimeOffset now)
    {
        if (feed.LastSuccessAtUtc is not { } lastSuccess)
        {
            return true;
        }

        var sinceSuccess = now - lastSuccess;
        return sinceSuccess > StaleAfter
               || (feed.LastAttemptStatus == IngestionJobStatus.Failed && sinceSuccess > FailureGrace);
    }
}
