using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Abstractions.Monetization;

public interface IAdUnlockSessionRepository : IRepository<AdUnlockSession, Guid>
{
}

public interface IRewardedAdViewRepository : IRepository<RewardedAdView, Guid>
{
    /// <summary>AdMob may repeat a callback; the transaction id identifies the view.</summary>
    Task<bool> ExistsAsync(string transactionId, CancellationToken cancellationToken = default);
}

public interface IFeatureGrantRepository : IRepository<FeatureGrant, Guid>
{
    /// <summary>Total quantity ever granted for a slot feature — the extra capacity the user has earned.</summary>
    Task<int> SumQuantityAsync(Guid userId, MonetizedFeature feature, CancellationToken cancellationToken = default);

    /// <summary>Unconsumed, unexpired grants of a single-use feature, oldest first (the next one to consume).</summary>
    Task<IReadOnlyList<FeatureGrant>> GetUsableAsync(Guid userId, MonetizedFeature feature, DateTimeOffset nowUtc, CancellationToken cancellationToken = default);

    /// <summary>Grants issued since <paramref name="sinceUtc"/>, optionally only from <paramref name="source"/> — daily caps.</summary>
    Task<int> CountGrantedSinceAsync(
        Guid userId, MonetizedFeature? feature, FeatureGrantSource? source, DateTimeOffset sinceUtc, CancellationToken cancellationToken = default);
}
