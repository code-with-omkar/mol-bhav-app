using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Monetization;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Promotions.Admin.GetAdminCampaigns;

internal sealed class GetAdminCampaignsQueryHandler(IPromotionReadService readService, TimeProvider timeProvider)
    : IQueryHandler<GetAdminCampaignsQuery, PagedResult<AdminCampaignResponse>>
{
    public async Task<Result<PagedResult<AdminCampaignResponse>>> Handle(GetAdminCampaignsQuery request, CancellationToken cancellationToken)
    {
        var filter = new AdminCampaignFilter(request.Status, request.AdvertiserId, new PageRequest(request.Page, request.PageSize));
        return Result.Success(await readService.GetCampaignsAsync(filter, IndiaDay.Today(timeProvider.GetUtcNow()), cancellationToken));
    }
}
