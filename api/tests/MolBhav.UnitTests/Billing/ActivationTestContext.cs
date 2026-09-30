using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Features.Billing.Activation;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;
using static MolBhav.UnitTests.Billing.BillingTestData;

namespace MolBhav.UnitTests.Billing;

/// <summary>A pending subscription for a real user, wired to substitute repositories and the real activation service.</summary>
internal sealed class ActivationTestContext
{
    public ActivationTestContext(string? couponCode = null)
    {
        User = User.Register(PhoneNumber.Create("9876543210").Value);
        Plan = ProMonthly();
        Subscription = Pending(User.Id, Plan, couponCode, couponCode is null ? 0 : 1_000);

        Subscriptions.GetByGatewayOrderIdAsync(Subscription.RazorpayOrderId!, Arg.Any<CancellationToken>()).Returns(Subscription);
        Plans.GetByIdAsync(Plan.Id, Arg.Any<CancellationToken>()).Returns(Plan);
        Users.GetByIdAsync(User.Id, Arg.Any<CancellationToken>()).Returns(User);
        Coupons.TryIncrementUsageAsync(Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns(1);

        Activation = new SubscriptionActivationService(
            Subscriptions, Coupons, Users, new FixedTimeProvider(Now), NullLogger<SubscriptionActivationService>.Instance);
    }

    public User User { get; }

    public Plan Plan { get; }

    public Subscription Subscription { get; }

    public ISubscriptionRepository Subscriptions { get; } = Substitute.For<ISubscriptionRepository>();

    public IPlanRepository Plans { get; } = Substitute.For<IPlanRepository>();

    public ICouponRepository Coupons { get; } = Substitute.For<ICouponRepository>();

    public IUserRepository Users { get; } = Substitute.For<IUserRepository>();

    public SubscriptionActivationService Activation { get; }
}
