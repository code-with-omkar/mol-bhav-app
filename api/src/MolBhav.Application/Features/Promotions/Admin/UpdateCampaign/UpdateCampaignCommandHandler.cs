using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Admin.UpdateCampaign;

internal sealed class UpdateCampaignCommandHandler(ICampaignRepository campaigns, CampaignInputResolver resolver)
    : ICommandHandler<UpdateCampaignCommand>
{
    public async Task<Result> Handle(UpdateCampaignCommand request, CancellationToken cancellationToken)
    {
        var campaign = await campaigns.GetByIdAsync(request.CampaignId, cancellationToken);
        if (campaign is null)
        {
            return PromotionErrors.CampaignNotFound;
        }

        var resolved = await resolver.ResolveAsync(request.Input!, cancellationToken);
        if (resolved.IsFailure)
        {
            return resolved.Error;
        }

        var input = resolved.Value;
        return campaign.Update(
            input.Name,
            input.Placement,
            input.Creative,
            input.StartsAtUtc,
            input.EndsAtUtc,
            input.Priority,
            input.DailyImpressionCap,
            input.Targets);
    }
}
