using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Monetization;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Admin.GetCampaignStats;

internal sealed class GetCampaignStatsQueryHandler(
    ICampaignRepository campaigns,
    IPromotionReadService readService,
    TimeProvider timeProvider)
    : IQueryHandler<GetCampaignStatsQuery, IReadOnlyList<CampaignDailyStatResponse>>
{
    private const int DefaultDays = 30;
    private const int MaxDays = 366;

    private static readonly Error RangeInvalid =
        Error.Validation("CampaignStats.RangeInvalid", $"The range must run forwards and cover at most {MaxDays} days.");

    public async Task<Result<IReadOnlyList<CampaignDailyStatResponse>>> Handle(GetCampaignStatsQuery request, CancellationToken cancellationToken)
    {
        var to = request.To ?? IndiaDay.Today(timeProvider.GetUtcNow());

        // Day-number arithmetic first: AddDays on an extreme date (0001-01-01) would throw instead of failing validation.
        var fromDayNumber = request.From?.DayNumber ?? to.DayNumber - (DefaultDays - 1);
        if (fromDayNumber < DateOnly.MinValue.DayNumber || fromDayNumber > to.DayNumber || to.DayNumber - fromDayNumber >= MaxDays)
        {
            return RangeInvalid;
        }

        if (await campaigns.GetByIdAsync(request.CampaignId, cancellationToken) is null)
        {
            return PromotionErrors.CampaignNotFound;
        }

        return Result.Success(await readService.GetDailyStatsAsync(
            request.CampaignId, DateOnly.FromDayNumber(fromDayNumber), to, cancellationToken));
    }
}
