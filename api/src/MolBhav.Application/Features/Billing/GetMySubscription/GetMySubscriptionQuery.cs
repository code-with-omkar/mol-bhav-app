using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.GetMySubscription;

public sealed record GetMySubscriptionQuery : IQuery<SubscriptionResponse>;
