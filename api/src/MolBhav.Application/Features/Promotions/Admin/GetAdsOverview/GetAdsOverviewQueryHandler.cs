using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Monetization;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Promotions.Admin.GetAdsOverview;

internal sealed class GetAdsOverviewQueryHandler(IPromotionReadService readService, TimeProvider timeProvider)
    : IQueryHandler<GetAdsOverviewQuery, AdsOverviewResponse>
{
    private const int DefaultDays = 30;
    private const int MaxDays = 366;

    private static readonly Error RangeInvalid =
        Error.Validation("AdsOverview.RangeInvalid", $"The range must run forwards and cover at most {MaxDays} days.");

    public async Task<Result<AdsOverviewResponse>> Handle(GetAdsOverviewQuery request, CancellationToken cancellationToken)
    {
        var to = request.To ?? IndiaDay.Today(timeProvider.GetUtcNow());

        // Day-number arithmetic first: AddDays on an extreme date (0001-01-01) would throw instead of failing validation.
        var fromDayNumber = request.From?.DayNumber ?? to.DayNumber - (DefaultDays - 1);
        if (fromDayNumber < DateOnly.MinValue.DayNumber || fromDayNumber > to.DayNumber || to.DayNumber - fromDayNumber >= MaxDays)
        {
            return RangeInvalid;
        }

        var from = DateOnly.FromDayNumber(fromDayNumber);
        var campaigns = await readService.GetCampaignPerformanceAsync(from, to, cancellationToken);
        var daily = await readService.GetTotalDailyStatsAsync(from, to, cancellationToken);

        var impressions = campaigns.Sum(c => c.Impressions);
        var clicks = campaigns.Sum(c => c.Clicks);

        return new AdsOverviewResponse(
            from,
            to,
            impressions,
            clicks,
            impressions == 0 ? 0 : Math.Round(100d * clicks / impressions, 1),
            campaigns,
            daily);
    }
}
