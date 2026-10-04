using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.ReconcilePayments;

/// <summary>
/// System query, sent by the reconciliation worker; not exposed over HTTP. Pending-payment subscriptions whose gateway
/// order was attached in the window, most recently changed first.
/// </summary>
public sealed record ListPendingPaymentsToReconcileQuery(DateTimeOffset ChangedFromUtc, DateTimeOffset ChangedToUtc, int Limit)
    : IQuery<IReadOnlyList<Guid>>;
