using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Promotions.Admin.UpdateCampaign;

public sealed record UpdateCampaignCommand(Guid CampaignId, CampaignInput? Input) : ICommand;
