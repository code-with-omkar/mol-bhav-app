using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Domain.Billing;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Billing;

internal sealed class PlanRepository(MolBhavDbContext dbContext) : Repository<Plan, Guid>(dbContext), IPlanRepository
{
    public Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(p => p.Code == code, cancellationToken);

    public Task<Plan?> GetByCodeAsync(string code, CancellationToken cancellationToken = default) =>
        Set.FirstOrDefaultAsync(p => p.Code == code, cancellationToken);
}
