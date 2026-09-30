using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Pricing;

internal sealed class PriceSourceRepository(MolBhavDbContext dbContext) : Repository<PriceSource, Guid>(dbContext), IPriceSourceRepository
{
    public Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(s => s.Code == code, cancellationToken);

    public async Task<IReadOnlyList<PriceSource>> GetActiveAsync(CancellationToken cancellationToken = default) =>
        await Set.AsNoTracking().Where(s => s.IsActive).ToArrayAsync(cancellationToken);
}
