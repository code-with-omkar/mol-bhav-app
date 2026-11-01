using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Promotions.Models;

namespace MolBhav.Application.Features.Promotions.Admin.GetAdsOverview;

/// <summary>
/// Sponsored-ad delivery across all campaigns for IST days <paramref name="From"/>–<paramref name="To"/> (inclusive;
/// default the last 30 days, at most 366).
/// </summary>
public sealed record GetAdsOverviewQuery(DateOnly? From, DateOnly? To) : IQuery<AdsOverviewResponse>;
