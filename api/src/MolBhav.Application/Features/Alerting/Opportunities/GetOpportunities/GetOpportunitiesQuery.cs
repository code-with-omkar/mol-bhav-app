using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Opportunities.Models;

namespace MolBhav.Application.Features.Alerting.Opportunities.GetOpportunities;

/// <summary>The signed-in user's market opportunities, newest first.</summary>
public sealed record GetOpportunitiesQuery(int Page, int PageSize) : IQuery<PagedResult<MarketOpportunityResponse>>;
