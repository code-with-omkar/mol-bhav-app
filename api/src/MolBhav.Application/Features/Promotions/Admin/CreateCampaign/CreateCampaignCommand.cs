using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Promotions.Admin.CreateCampaign;

/// <summary>Creates a campaign as <c>Draft</c>; it serves only after it is activated.</summary>
public sealed record CreateCampaignCommand(Guid AdvertiserId, CampaignInput? Input) : ICommand<CreatedResponse>;
