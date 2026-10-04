using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Admin.SetCampaignStatus;

internal sealed class SetCampaignStatusCommandHandler(ICampaignRepository campaigns, TimeProvider timeProvider)
    : ICommandHandler<SetCampaignStatusCommand>
{
    public async Task<Result> Handle(SetCampaignStatusCommand request, CancellationToken cancellationToken)
    {
        var campaign = await campaigns.GetByIdAsync(request.CampaignId, cancellationToken);
        if (campaign is null)
        {
            return PromotionErrors.CampaignNotFound;
        }

        switch (request.Action!.Value)
        {
            case CampaignStatusAction.Activate:
                return campaign.Activate(timeProvider.GetUtcNow());
            case CampaignStatusAction.Pause:
                return campaign.Pause();
            default:
                campaign.End();
                return Result.Success();
        }
    }
}
