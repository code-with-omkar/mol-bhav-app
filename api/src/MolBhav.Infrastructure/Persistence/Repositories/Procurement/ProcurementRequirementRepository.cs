using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Domain.Procurement;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Procurement;

internal sealed class ProcurementRequirementRepository(MolBhavDbContext dbContext)
    : Repository<ProcurementRequirement, Guid>(dbContext), IProcurementRequirementRepository
{
}
