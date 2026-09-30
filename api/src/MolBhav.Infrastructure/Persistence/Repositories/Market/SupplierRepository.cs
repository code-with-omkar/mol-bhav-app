using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Domain.Market;

namespace MolBhav.Infrastructure.Persistence.Repositories.Market;

internal sealed class SupplierRepository(MolBhavDbContext dbContext) : Repository<Supplier, Guid>(dbContext), ISupplierRepository
{
    public Task<bool> CodeExistsAsync(MarketCode code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(s => s.Code == code, cancellationToken);

    public Task<Supplier?> GetByCodeAsync(MarketCode code, CancellationToken cancellationToken = default) =>
        Set.SingleOrDefaultAsync(s => s.Code == code && s.IsActive, cancellationToken);
}
