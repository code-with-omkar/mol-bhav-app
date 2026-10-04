using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Domain.Billing;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Billing;

internal sealed class SubscriptionRepository(MolBhavDbContext dbContext) : Repository<Subscription, Guid>(dbContext), ISubscriptionRepository
{
    public Task<Subscription?> GetActiveByUserAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Set.FirstOrDefaultAsync(s => s.UserId == userId && s.Status == SubscriptionStatus.Active, cancellationToken);

    public Task<Subscription?> GetPendingByUserAndPlanAsync(Guid userId, Guid planId, CancellationToken cancellationToken = default) =>
        Set.FirstOrDefaultAsync(s => s.UserId == userId && s.PlanId == planId && s.Status == SubscriptionStatus.PendingPayment, cancellationToken);

    public Task<Subscription?> GetByGatewayOrderIdAsync(string orderId, CancellationToken cancellationToken = default) =>
        Set.FirstOrDefaultAsync(s => s.RazorpayOrderId == orderId, cancellationToken);

    // Served by the partial index ix_subscriptions_active_expires_at_utc (AddSubscriptionExpiryIndex): the sweep
    // touches only Active rows instead of scanning billing history.
    public async Task<IReadOnlyList<Subscription>> GetLapsedActiveAsync(DateTimeOffset nowUtc, int batchSize, CancellationToken cancellationToken = default) =>
        await Set
            .Where(s => s.Status == SubscriptionStatus.Active && s.ExpiresAtUtc <= nowUtc)
            .OrderBy(s => s.ExpiresAtUtc)
            .Take(batchSize)
            .ToListAsync(cancellationToken);

    // No dedicated index: pending rows are abandoned or in-flight checkouts, a small slice of a small table, and the
    // sweep runs every few minutes. Revisit (partial index WHERE status = 'PendingPayment') if billing history grows large.
    public async Task<IReadOnlyList<Guid>> GetPendingPaymentIdsChangedBetweenAsync(
        DateTimeOffset changedFromUtc, DateTimeOffset changedToUtc, int limit, CancellationToken cancellationToken = default) =>
        await Set
            .AsNoTracking()
            .Where(s => s.Status == SubscriptionStatus.PendingPayment && s.RazorpayOrderId != null)
            .Where(s => (s.UpdatedAtUtc ?? s.CreatedAtUtc) >= changedFromUtc && (s.UpdatedAtUtc ?? s.CreatedAtUtc) <= changedToUtc)
            .OrderByDescending(s => s.UpdatedAtUtc ?? s.CreatedAtUtc)
            .Select(s => s.Id)
            .Take(limit)
            .ToListAsync(cancellationToken);
}
