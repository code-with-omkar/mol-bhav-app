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
}
