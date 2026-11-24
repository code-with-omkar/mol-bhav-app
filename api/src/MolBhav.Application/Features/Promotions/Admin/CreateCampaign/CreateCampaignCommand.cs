using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Promotions.Admin.CreateCampaign;

/// <summary>Creates a campaign as <c>Draft</c>; it serves only after it is activated.</summary>
public sealed record CreateCampaignCommand(Guid AdvertiserId, CampaignInput? Input) : ICommand<CreatedResponse>, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Campaign.Create";

    string? IAuditedCommand.AuditTarget => Input?.Name?.Trim();

    string IAuditedCommand.AuditSummary => "Created an ad campaign (draft)";
}
