using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Admin.CreateCampaign;

internal sealed class CreateCampaignCommandHandler(
    ICampaignRepository campaigns,
    IAdvertiserRepository advertisers,
    CampaignInputResolver resolver) : ICommandHandler<CreateCampaignCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateCampaignCommand request, CancellationToken cancellationToken)
    {
        if (await advertisers.GetByIdAsync(request.AdvertiserId, cancellationToken) is null)
        {
            return PromotionErrors.AdvertiserNotFound;
        }

        var resolved = await resolver.ResolveAsync(request.Input!, cancellationToken);
        if (resolved.IsFailure)
        {
            return Result.Failure<CreatedResponse>(resolved.Error);
        }

        var input = resolved.Value;
        var campaign = Campaign.Create(
            request.AdvertiserId,
            input.Name,
            input.Placement,
            input.Creative,
            input.StartsAtUtc,
            input.EndsAtUtc,
            input.Priority,
            input.DailyImpressionCap,
            input.Targets);
        if (campaign.IsFailure)
        {
            return Result.Failure<CreatedResponse>(campaign.Error);
        }

        campaigns.Add(campaign.Value);
        return new CreatedResponse(campaign.Value.Id);
    }
}
