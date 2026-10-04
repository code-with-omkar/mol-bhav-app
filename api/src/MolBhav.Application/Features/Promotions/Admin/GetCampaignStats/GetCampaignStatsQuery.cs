using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Promotions.Models;

namespace MolBhav.Application.Features.Promotions.Admin.GetCampaignStats;

/// <summary>Daily delivery for one campaign; defaults to the last 30 IST days.</summary>
public sealed record GetCampaignStatsQuery(Guid CampaignId, DateOnly? From, DateOnly? To) : IQuery<IReadOnlyList<CampaignDailyStatResponse>>;
