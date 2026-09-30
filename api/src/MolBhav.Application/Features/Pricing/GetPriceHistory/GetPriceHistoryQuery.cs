using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.GetPriceHistory;

/// <summary>Trend sparkline for one product at one location, oldest first (BRD §11/§12).</summary>
public sealed record GetPriceHistoryQuery(Guid ProductId, LocationKind LocationKind, Guid LocationId, DateOnly FromDate, DateOnly ToDate)
    : IQuery<IReadOnlyList<PriceHistoryPointResponse>>;
