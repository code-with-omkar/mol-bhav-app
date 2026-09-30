using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Domain.Procurement;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Procurement;

internal sealed class CostComponentRepository(MolBhavDbContext dbContext) : Repository<CostComponent, Guid>(dbContext), ICostComponentRepository
{
    public Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(c => c.Code == code, cancellationToken);

    public async Task<IReadOnlyList<CostComponent>> GetActiveAsync(CancellationToken cancellationToken = default) =>
        await Set.AsNoTracking().Where(c => c.IsActive).ToArrayAsync(cancellationToken);
}
