using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Procurement.Models;

namespace MolBhav.Application.Features.Procurement.ComputeOpportunities;

/// <summary>Refreshes a requirement's opportunity list against current prices (BRD §13). Not a query: it persists a
/// new snapshot batch every time it runs, so re-running it is a deliberate refresh, not a free read.</summary>
public sealed record ComputeOpportunitiesCommand(Guid RequirementId) : ICommand<IReadOnlyList<ProcurementOpportunityResponse>>;
