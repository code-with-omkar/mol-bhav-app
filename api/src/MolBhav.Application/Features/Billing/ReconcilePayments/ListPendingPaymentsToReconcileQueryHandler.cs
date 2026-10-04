using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.ReconcilePayments;

/// <summary>Ids only: each candidate is then reconciled in its own unit of work, so one failure never blocks the rest.</summary>
internal sealed class ListPendingPaymentsToReconcileQueryHandler(ISubscriptionRepository subscriptions)
    : IQueryHandler<ListPendingPaymentsToReconcileQuery, IReadOnlyList<Guid>>
{
    public async Task<Result<IReadOnlyList<Guid>>> Handle(ListPendingPaymentsToReconcileQuery request, CancellationToken cancellationToken)
    {
        var ids = await subscriptions.GetPendingPaymentIdsChangedBetweenAsync(
            request.ChangedFromUtc, request.ChangedToUtc, request.Limit, cancellationToken);

        return Result.Success(ids);
    }
}
