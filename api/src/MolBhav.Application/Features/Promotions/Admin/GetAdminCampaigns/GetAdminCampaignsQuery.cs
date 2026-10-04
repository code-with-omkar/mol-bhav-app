using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Admin.GetAdminCampaigns;

public sealed record GetAdminCampaignsQuery(CampaignStatus? Status, Guid? AdvertiserId, int Page, int PageSize)
    : IQuery<PagedResult<AdminCampaignResponse>>;
