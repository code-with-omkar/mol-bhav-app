using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Abstractions.Procurement;

public interface IProcurementRequirementRepository : IRepository<ProcurementRequirement, Guid>
{
}

public interface IProcurementOpportunityRepository : IRepository<ProcurementOpportunity, Guid>
{
}

public interface ICostComponentRepository : IRepository<CostComponent, Guid>
{
    Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default);

    /// <summary>Every active component, applied in order when computing an opportunity's estimated cost.</summary>
    Task<IReadOnlyList<CostComponent>> GetActiveAsync(CancellationToken cancellationToken = default);
}
