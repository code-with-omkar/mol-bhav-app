using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Promotions.Admin.SetCampaignStatus;

public enum CampaignStatusAction
{
    Activate = 0,
    Pause = 1,
    End = 2,
}

public sealed record SetCampaignStatusCommand(Guid CampaignId, CampaignStatusAction? Action) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Campaign.SetStatus";

    string? IAuditedCommand.AuditTarget => CampaignId.ToString();

    string IAuditedCommand.AuditSummary => Action switch
    {
        CampaignStatusAction.Activate => "Activated an ad campaign",
        CampaignStatusAction.Pause => "Paused an ad campaign",
        CampaignStatusAction.End => "Ended an ad campaign",
        _ => "Changed an ad campaign's status",
    };
}
