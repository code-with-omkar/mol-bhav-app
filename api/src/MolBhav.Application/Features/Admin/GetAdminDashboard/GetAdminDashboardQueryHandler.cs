using MolBhav.Application.Abstractions.Admin;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Application.Features.Monetization;
using MolBhav.Application.Features.Pricing.GetPriceDataStatus;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Admin.GetAdminDashboard;

internal sealed class GetAdminDashboardQueryHandler(
    IAdminDashboardReadService readService,
    IIngestionReadService ingestion,
    TimeProvider timeProvider) : IQueryHandler<GetAdminDashboardQuery, AdminDashboardResponse>
{
    public async Task<Result<AdminDashboardResponse>> Handle(GetAdminDashboardQuery request, CancellationToken cancellationToken)
    {
        var now = timeProvider.GetUtcNow();
        var counts = await readService.GetCountsAsync(IndiaDay.Today(now), now, cancellationToken);
        var feeds = await ingestion.GetScheduledFeedHealthAsync(cancellationToken);

        return new AdminDashboardResponse(
            counts.Users,
            counts.Ads,
            new AdminFeedsSummary(
                IsDelayed: feeds.Any(f => GetPriceDataStatusQueryHandler.IsDelayed(f, now)),
                LastSuccessAtUtc: feeds.Max(f => f.LastSuccessAtUtc),
                LastAttemptStatus: feeds.OrderByDescending(f => f.LastAttemptAtUtc).FirstOrDefault()?.LastAttemptStatus,
                LastAttemptAtUtc: feeds.Max(f => f.LastAttemptAtUtc)),
            counts.Support,
            now);
    }
}
