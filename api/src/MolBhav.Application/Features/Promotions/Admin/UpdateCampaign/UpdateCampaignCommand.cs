using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Promotions.Admin.UpdateCampaign;

public sealed record UpdateCampaignCommand(Guid CampaignId, CampaignInput? Input) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Campaign.Update";

    string? IAuditedCommand.AuditTarget => CampaignId.ToString();

    string IAuditedCommand.AuditSummary => "Edited an ad campaign";
}
