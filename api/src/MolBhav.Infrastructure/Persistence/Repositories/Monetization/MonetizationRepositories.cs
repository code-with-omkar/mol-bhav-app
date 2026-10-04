using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Domain.Monetization;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Monetization;

internal sealed class AdUnlockSessionRepository(MolBhavDbContext dbContext)
    : Repository<AdUnlockSession, Guid>(dbContext), IAdUnlockSessionRepository
{
}

internal sealed class RewardedAdViewRepository(MolBhavDbContext dbContext)
    : Repository<RewardedAdView, Guid>(dbContext), IRewardedAdViewRepository
{
    public Task<bool> ExistsAsync(string transactionId, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(v => v.TransactionId == transactionId, cancellationToken);
}

internal sealed class FeatureGrantRepository(MolBhavDbContext dbContext)
    : Repository<FeatureGrant, Guid>(dbContext), IFeatureGrantRepository
{
    public async Task<int> SumQuantityAsync(Guid userId, MonetizedFeature feature, CancellationToken cancellationToken = default) =>
        await Set.Where(g => g.UserId == userId && g.Feature == feature)
            .SumAsync(g => (int?)g.Quantity, cancellationToken) ?? 0;

    /// <summary>Tracked: the caller consumes the first one inside its unit of work.</summary>
    public async Task<IReadOnlyList<FeatureGrant>> GetUsableAsync(
        Guid userId, MonetizedFeature feature, DateTimeOffset nowUtc, CancellationToken cancellationToken = default) =>
        await Set.Where(g => g.UserId == userId
                && g.Feature == feature
                && g.ConsumedAtUtc == null
                && (g.ExpiresAtUtc == null || g.ExpiresAtUtc > nowUtc))
            .OrderBy(g => g.GrantedAtUtc)
            .ToArrayAsync(cancellationToken);

    public Task<int> CountGrantedSinceAsync(
        Guid userId, MonetizedFeature? feature, FeatureGrantSource? source, DateTimeOffset sinceUtc, CancellationToken cancellationToken = default) =>
        Set.CountAsync(
            g => g.UserId == userId
                && (feature == null || g.Feature == feature)
                && (source == null || g.Source == source)
                && g.GrantedAtUtc >= sinceUtc,
            cancellationToken);
}
