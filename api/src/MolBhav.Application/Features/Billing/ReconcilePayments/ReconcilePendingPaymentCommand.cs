using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.ReconcilePayments;

/// <summary>
/// System command, sent by the reconciliation worker; not exposed over HTTP. Asks the gateway whether the subscription's
/// order was paid and activates it if so — the safety net for payment webhooks that never arrived.
/// </summary>
public sealed record ReconcilePendingPaymentCommand(Guid SubscriptionId) : ICommand<PaymentReconciliationOutcome>;

public enum PaymentReconciliationOutcome
{
    /// <summary>Already activated, cancelled or without an order (e.g. the webhook won the race); nothing to do.</summary>
    NotPending = 0,

    /// <summary>The order has no captured payment yet (usually an abandoned checkout).</summary>
    NoCapturedPayment = 1,

    /// <summary>A captured payment exists but none matches the charge; needs a human (refund).</summary>
    AmountMismatch = 2,

    /// <summary>Activated from a captured payment the webhook never delivered.</summary>
    Activated = 3,
}
