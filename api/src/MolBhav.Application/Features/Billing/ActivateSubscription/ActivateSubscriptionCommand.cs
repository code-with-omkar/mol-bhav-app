using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.ActivateSubscription;

public sealed record ActivateSubscriptionCommand(
    string RazorpayOrderId,
    string RazorpayPaymentId,
    string RazorpaySignature) : ICommand<SubscriptionResponse>;
