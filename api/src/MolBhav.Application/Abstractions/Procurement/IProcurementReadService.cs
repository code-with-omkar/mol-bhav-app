using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Features.Procurement.Models;

namespace MolBhav.Application.Abstractions.Procurement;

/// <summary>Dapper-backed reads for the signed-in user's requirements/opportunities and the admin cost-component list.</summary>
public interface IProcurementReadService
{
    Task<IReadOnlyList<ProcurementRequirementResponse>> GetMyRequirementsAsync(
        Guid userId, LanguagePreference language, CancellationToken cancellationToken = default);

    /// <summary>Cheapest first. Empty when the requirement doesn't exist, belongs to someone else, or has never been computed.</summary>
    Task<IReadOnlyList<ProcurementOpportunityResponse>> GetOpportunitiesAsync(
        Guid requirementId, Guid userId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AdminCostComponentResponse>> GetAdminCostComponentsAsync(CancellationToken cancellationToken = default);
}
