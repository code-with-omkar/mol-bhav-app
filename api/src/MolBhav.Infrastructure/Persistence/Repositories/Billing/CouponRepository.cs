using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Domain.Billing;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Billing;

internal sealed class CouponRepository(MolBhavDbContext dbContext) : Repository<Coupon, Guid>(dbContext), ICouponRepository
{
    public Task<Coupon?> GetByCodeAsync(string code, CancellationToken cancellationToken = default) =>
        Set.FirstOrDefaultAsync(c => c.Code == code, cancellationToken);

    // One conditional UPDATE, run immediately inside the ambient transaction: the WHERE clause is re-evaluated under
    // the row lock, so two activations racing for the last use cannot both succeed.
    public Task<int> TryIncrementUsageAsync(string code, CancellationToken cancellationToken = default) =>
        Set.Where(c => c.Code == code && (c.MaxUses == null || c.UsesCount < c.MaxUses))
            .ExecuteUpdateAsync(s => s.SetProperty(c => c.UsesCount, c => c.UsesCount + 1), cancellationToken);
}
