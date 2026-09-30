using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Procurement.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Features.Procurement.ComputeOpportunities;

/// <summary>
/// Prices the requirement's quantity at every candidate location (BRD §13's "compare available market/supplier
/// prices"), applies every active <see cref="CostComponent"/> on top, and persists the resulting snapshot batch
/// (cheapest first). Reuses <see cref="IPricingReadService"/> rather than duplicating the latest-price query.
/// </summary>
internal sealed class ComputeOpportunitiesCommandHandler(
    IProcurementRequirementRepository requirements,
    IProcurementOpportunityRepository opportunities,
    ICostComponentRepository costComponents,
    IPricingReadService pricingReadService,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : ICommandHandler<ComputeOpportunitiesCommand, IReadOnlyList<ProcurementOpportunityResponse>>
{
    private const int MaxCandidates = 50;
    private const int MaxOpportunities = 10;

    public async Task<Result<IReadOnlyList<ProcurementOpportunityResponse>>> Handle(
        ComputeOpportunitiesCommand request, CancellationToken cancellationToken)
    {
        var requirement = await requirements.GetByIdAsync(request.RequirementId, cancellationToken);
        if (requirement is null || requirement.UserId != currentUser.GetRequiredUserId())
        {
            return Error.NotFound("ProcurementRequirement.NotFound", "Requirement not found.");
        }

        var candidates = await pricingReadService.GetLatestPricesAsync(
            new LatestPriceFilter(requirement.ProductId, null, requirement.TargetDistrictId, new PageRequest(1, MaxCandidates)),
            cancellationToken);

        if (candidates.Items.Count == 0)
        {
            return Result.Success<IReadOnlyList<ProcurementOpportunityResponse>>([]);
        }

        var activeComponents = await costComponents.GetActiveAsync(cancellationToken);
        var nowUtc = timeProvider.GetUtcNow();
        var targetTotal = requirement.TargetPrice is { } target ? target * requirement.Quantity : (decimal?)null;

        var priced = candidates.Items
            .Select(candidate =>
            {
                var baseCost = requirement.Quantity * candidate.ModalPrice;
                var estimatedCost = baseCost + activeComponents.Sum(c => c.Apply(baseCost));
                var savings = targetTotal - estimatedCost;
                return (Candidate: candidate, EstimatedCost: estimatedCost, Savings: savings);
            })
            .OrderBy(x => x.EstimatedCost)
            .Take(MaxOpportunities)
            .ToArray();

        var responses = new List<ProcurementOpportunityResponse>(priced.Length);

        foreach (var (candidate, estimatedCost, savings) in priced)
        {
            var opportunity = ProcurementOpportunity.Create(
                requirement.Id,
                candidate.LocationKind,
                candidate.LocationId,
                candidate.LocationName,
                requirement.Quantity,
                candidate.ModalPrice,
                estimatedCost,
                savings,
                candidate.RecordDate,
                nowUtc);

            if (opportunity.IsFailure)
            {
                continue;
            }

            opportunities.Add(opportunity.Value);
            responses.Add(new ProcurementOpportunityResponse(
                opportunity.Value.Id,
                opportunity.Value.LocationKind,
                opportunity.Value.LocationId,
                opportunity.Value.LocationName,
                opportunity.Value.Quantity,
                opportunity.Value.UnitPrice,
                opportunity.Value.EstimatedCost,
                opportunity.Value.SavingsVsTarget,
                opportunity.Value.PriceRecordDate,
                opportunity.Value.ComputedAtUtc));
        }

        return Result.Success<IReadOnlyList<ProcurementOpportunityResponse>>(responses);
    }
}
