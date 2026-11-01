using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Alerting.Opportunities.ScanMarketOpportunities;

/// <summary>Looks for cheaper markets for every watchlist item (daily job, or "Find now" in Admin). Safe to repeat:
/// a user gets at most one opportunity per product per IST day.</summary>
public sealed record ScanMarketOpportunitiesCommand : ICommand<OpportunityScanResult>;

public sealed record OpportunityScanResult(int WatchedItems, int Compared, int Found, DateOnly DetectedOn);
