using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Abstractions.Billing;

public interface IPlanRepository : IRepository<Plan, Guid>
{
    Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default);
    Task<Plan?> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
}

public interface ISubscriptionRepository : IRepository<Subscription, Guid>
{
    /// <summary>The user's current active subscription, if any.</summary>
    Task<Subscription?> GetActiveByUserAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>An in-flight pending-payment subscription for this user+plan, if any (reused on checkout retry).</summary>
    Task<Subscription?> GetPendingByUserAndPlanAsync(Guid userId, Guid planId, CancellationToken cancellationToken = default);

    Task<Subscription?> GetByGatewayOrderIdAsync(string orderId, CancellationToken cancellationToken = default);

    /// <summary>Active subscriptions whose paid period ended at or before <paramref name="nowUtc"/>, oldest first, at most <paramref name="batchSize"/>.</summary>
    Task<IReadOnlyList<Subscription>> GetLapsedActiveAsync(DateTimeOffset nowUtc, int batchSize, CancellationToken cancellationToken = default);
}

public interface ICouponRepository : IRepository<Coupon, Guid>
{
    /// <summary>Expects a code already normalised with <see cref="Coupon.NormaliseCode"/>.</summary>
    Task<Coupon?> GetByCodeAsync(string code, CancellationToken cancellationToken = default);

    /// <summary>
    /// Counts one use in a single conditional UPDATE, so concurrent activations can never push the count past
    /// <see cref="Coupon.MaxUses"/>. Returns the number of rows updated: 0 when the cap is reached or the code is unknown.
    /// </summary>
    Task<int> TryIncrementUsageAsync(string code, CancellationToken cancellationToken = default);
}
