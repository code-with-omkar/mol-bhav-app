using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Alerting.Opportunities.Models;

namespace MolBhav.Application.Features.Alerting.Opportunities.GetOpportunity;

/// <summary>One opportunity plus every market's current price for the same product/variant.</summary>
public sealed record GetOpportunityQuery(Guid OpportunityId) : IQuery<MarketOpportunityDetailResponse>;
