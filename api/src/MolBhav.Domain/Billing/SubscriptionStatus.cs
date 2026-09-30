namespace MolBhav.Domain.Billing;

public enum SubscriptionStatus
{
    Active = 0,
    Cancelled = 1,
    Expired = 2,

    /// <summary>Order created with the gateway; awaiting client-side payment confirmation.</summary>
    PendingPayment = 3,
}
