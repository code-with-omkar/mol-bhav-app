using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Features.Billing.Subscribe;
using MolBhav.Domain.Billing;
using static MolBhav.UnitTests.Billing.BillingTestData;

namespace MolBhav.UnitTests.Billing;

public sealed class SubscribeCommandHandlerTests
{
    private readonly Guid _userId = Guid.CreateVersion7();
    private readonly Plan _plan = ProMonthly(499m);
    private readonly IPlanRepository _plans = Substitute.For<IPlanRepository>();
    private readonly ISubscriptionRepository _subscriptions = Substitute.For<ISubscriptionRepository>();
    private readonly ICouponRepository _coupons = Substitute.For<ICouponRepository>();
    private readonly IPaymentGateway _gateway = Substitute.For<IPaymentGateway>();
    private readonly SubscribeCommandHandler _handler;

    public SubscribeCommandHandlerTests()
    {
        var currentUser = Substitute.For<ICurrentUser>();
        currentUser.GetRequiredUserId().Returns(_userId);

        _plans.GetByCodeAsync(_plan.Code, Arg.Any<CancellationToken>()).Returns(_plan);
        _gateway.CreateOrderAsync(Arg.Any<CreateOrderRequest>(), Arg.Any<CancellationToken>())
            .Returns(call =>
            {
                var request = call.Arg<CreateOrderRequest>();
                return new CreateOrderResult("order_new", request.AmountPaise, request.Currency, true, null);
            });

        _handler = new SubscribeCommandHandler(_plans, _subscriptions, _coupons, _gateway, currentUser, new FixedTimeProvider(Now));
    }

    [Fact]
    public async Task Handle_ChargesTheServerSidePlanPrice()
    {
        var result = await _handler.Handle(new SubscribeCommand(_plan.Code, null), CancellationToken.None);

        Assert.True(result.IsSuccess);
        await _gateway.Received(1).CreateOrderAsync(
            Arg.Is<CreateOrderRequest>(r => r.AmountPaise == 49_900 && r.Currency == "INR"), Arg.Any<CancellationToken>());
        Assert.Equal(49_900, result.Value.AmountPaise);
    }

    [Fact]
    public async Task Handle_WithCoupon_ChargesTheDiscountedAmount()
    {
        _coupons.GetByCodeAsync("LAUNCH50", Arg.Any<CancellationToken>()).Returns(Coupon(DiscountType.Percent, 10));

        var result = await _handler.Handle(new SubscribeCommand(_plan.Code, "launch50"), CancellationToken.None);

        Assert.Equal(44_910, result.Value.AmountPaise);
        await _coupons.DidNotReceive().TryIncrementUsageAsync(Arg.Any<string>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_UnusableCoupon_Fails()
    {
        _coupons.GetByCodeAsync("LAUNCH50", Arg.Any<CancellationToken>()).Returns(Coupon(validTo: Now.AddMinutes(-1), validFrom: Now.AddDays(-5)));

        var result = await _handler.Handle(new SubscribeCommand(_plan.Code, "launch50"), CancellationToken.None);

        Assert.Equal(BillingErrors.CouponInvalid, result.Error);
        await _gateway.DidNotReceive().CreateOrderAsync(Arg.Any<CreateOrderRequest>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_GatewayFailure_ReturnsGatewayUnavailable()
    {
        _gateway.CreateOrderAsync(Arg.Any<CreateOrderRequest>(), Arg.Any<CancellationToken>())
            .Returns(call => CreateOrderResult.Failed(call.Arg<CreateOrderRequest>(), "down"));

        var result = await _handler.Handle(new SubscribeCommand(_plan.Code, null), CancellationToken.None);

        Assert.Equal(BillingErrors.GatewayUnavailable, result.Error);
    }

    [Fact]
    public async Task Handle_ExistingPendingSubscription_IsReused()
    {
        var pending = Pending(_userId, _plan);
        _subscriptions.GetPendingByUserAndPlanAsync(_userId, _plan.Id, Arg.Any<CancellationToken>()).Returns(pending);

        var result = await _handler.Handle(new SubscribeCommand(_plan.Code, null), CancellationToken.None);

        Assert.Equal(pending.Id, result.Value.SubscriptionId);
        Assert.Equal("order_new", pending.RazorpayOrderId);
        _subscriptions.DidNotReceive().Add(Arg.Any<Subscription>());
    }

    [Fact]
    public async Task Handle_ActiveSubscriptionOutsideRenewalWindow_Conflicts()
    {
        _subscriptions.GetActiveByUserAsync(_userId, Arg.Any<CancellationToken>()).Returns(Active(_userId, _plan, Now));

        var result = await _handler.Handle(new SubscribeCommand(_plan.Code, null), CancellationToken.None);

        Assert.Equal(BillingErrors.AlreadySubscribed, result.Error);
    }

    [Fact]
    public async Task Handle_ActiveSubscriptionInsideRenewalWindow_OpensOrder()
    {
        _subscriptions.GetActiveByUserAsync(_userId, Arg.Any<CancellationToken>()).Returns(Active(_userId, _plan, Now.AddDays(-25)));

        var result = await _handler.Handle(new SubscribeCommand(_plan.Code, null), CancellationToken.None);

        Assert.True(result.IsSuccess);
    }
}
