using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Domain.Identity;

namespace MolBhav.Infrastructure.Persistence.Repositories.Identity;

internal sealed class RefreshTokenRepository(MolBhavDbContext dbContext)
    : Repository<RefreshTokenGrant, Guid>(dbContext), IRefreshTokenRepository
{
    public Task<RefreshTokenGrant?> GetByTokenHashAsync(string tokenHash, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(tokenHash);
        return Set.SingleOrDefaultAsync(t => t.TokenHash == tokenHash, cancellationToken);
    }

    public async Task<IReadOnlyCollection<RefreshTokenGrant>> GetActiveFamilyAsync(Guid familyId, CancellationToken cancellationToken = default) =>
        await Set
            .Where(t => t.FamilyId == familyId && t.RevokedAtUtc == null)
            .ToListAsync(cancellationToken);
}
