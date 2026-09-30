using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Billing.Models;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Abstractions.Billing;

/// <summary>Dapper-backed reads for the plan catalog, the signed-in user's subscription, and admin billing screens.</summary>
public interface IBillingReadService
{
    Task<IReadOnlyList<PlanResponse>> GetActivePlansAsync(CancellationToken cancellationToken = default);

    /// <summary>Null when the user has never subscribed.</summary>
    Task<SubscriptionResponse?> GetMySubscriptionAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AdminPlanResponse>> GetAdminPlansAsync(CancellationToken cancellationToken = default);

    Task<PagedResult<AdminSubscriptionResponse>> GetAdminSubscriptionsAsync(AdminSubscriptionFilter filter, CancellationToken cancellationToken = default);

    Task<PagedResult<AdminCouponResponse>> GetAdminCouponsAsync(PageRequest page, CancellationToken cancellationToken = default);
}

public sealed record AdminSubscriptionFilter(Guid? UserId, SubscriptionStatus? Status, PageRequest Page);
