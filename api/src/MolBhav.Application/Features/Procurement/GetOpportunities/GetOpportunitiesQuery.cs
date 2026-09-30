using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Procurement.Models;

namespace MolBhav.Application.Features.Procurement.GetOpportunities;

public sealed record GetOpportunitiesQuery(Guid RequirementId) : IQuery<IReadOnlyList<ProcurementOpportunityResponse>>;
