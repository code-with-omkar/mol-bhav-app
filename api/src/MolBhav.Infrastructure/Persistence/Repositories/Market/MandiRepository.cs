using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Domain.Market;

namespace MolBhav.Infrastructure.Persistence.Repositories.Market;

internal sealed class MandiRepository(MolBhavDbContext dbContext) : Repository<Mandi, Guid>(dbContext), IMandiRepository
{
    public Task<bool> CodeExistsAsync(MarketCode code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(m => m.Code == code, cancellationToken);

    public Task<Mandi?> GetByCodeAsync(MarketCode code, CancellationToken cancellationToken = default) =>
        Set.SingleOrDefaultAsync(m => m.Code == code && m.IsActive, cancellationToken);
}
