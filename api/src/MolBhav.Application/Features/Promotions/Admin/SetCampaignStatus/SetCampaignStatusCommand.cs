using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Promotions.Admin.SetCampaignStatus;

public enum CampaignStatusAction
{
    Activate = 0,
    Pause = 1,
    End = 2,
}

public sealed record SetCampaignStatusCommand(Guid CampaignId, CampaignStatusAction? Action) : ICommand;
