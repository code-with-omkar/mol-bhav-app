using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Features.Billing.ActivateSubscription;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Identity;
using static MolBhav.UnitTests.Billing.BillingTestData;

namespace MolBhav.UnitTests.Billing;

public sealed class ActivateSubscriptionCommandHandlerTests
{
    private readonly ActivationTestContext _context = new(couponCode: "LAUNCH50");
    private readonly IPaymentGateway _gateway = Substitute.For<IPaymentGateway>();
    private readonly ICurrentUser _currentUser = Substitute.For<ICurrentUser>();
    private readonly ActivateSubscriptionCommandHandler _handler;

    public ActivateSubscriptionCommandHandlerTests()
    {
        _currentUser.GetRequiredUserId().Returns(_context.User.Id);
        _gateway.VerifyCheckoutSignature(Arg.Any<string>(), Arg.Any<string>(), "good").Returns(true);

        _handler = new ActivateSubscriptionCommandHandler(
            _context.Subscriptions, _context.Plans, _gateway, _context.Activation, _currentUser);
    }

    private ActivateSubscriptionCommand Command(string signature = "good") =>
        new(_context.Subscription.RazorpayOrderId!, "pay_1", signature);

    [Fact]
    public async Task Handle_ValidSignature_ActivatesAndMakesUserPro()
    {
        var result = await _handler.Handle(Command(), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(SubscriptionStatus.Active, _context.Subscription.Status);
        Assert.Equal(Now.AddMonths(1), _context.Subscription.ExpiresAtUtc);
        Assert.Equal(SubscriptionTier.Pro, _context.User.SubscriptionTier);
        await _context.Coupons.Received(1).TryIncrementUsageAsync("LAUNCH50", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_AnotherUsersOrder_IsNotFound()
    {
        _currentUser.GetRequiredUserId().Returns(Guid.CreateVersion7());

        var result = await _handler.Handle(Command(), CancellationToken.None);

        Assert.Equal(BillingErrors.SubscriptionNotFound, result.Error);
        Assert.Equal(SubscriptionStatus.PendingPayment, _context.Subscription.Status);
    }

    [Fact]
    public async Task Handle_BadSignature_IsRejected()
    {
        var result = await _handler.Handle(Command("forged"), CancellationToken.None);

        Assert.Equal(BillingErrors.InvalidSignature, result.Error);
        Assert.Equal(SubscriptionStatus.PendingPayment, _context.Subscription.Status);
    }

    [Fact]
    public async Task Handle_Twice_IsIdempotent()
    {
        await _handler.Handle(Command(), CancellationToken.None);
        var expiry = _context.Subscription.ExpiresAtUtc;

        var second = await _handler.Handle(Command(), CancellationToken.None);

        Assert.True(second.IsSuccess);
        Assert.Equal(expiry, _context.Subscription.ExpiresAtUtc);
        await _context.Coupons.Received(1).TryIncrementUsageAsync(Arg.Any<string>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_EarlyRenewal_ContinuesFromCurrentExpiryAndSupersedesIt()
    {
        var current = Active(_context.User.Id, _context.Plan, Now.AddDays(-25));
        _context.Subscriptions.GetActiveByUserAsync(_context.User.Id, Arg.Any<CancellationToken>()).Returns(current);

        await _handler.Handle(Command(), CancellationToken.None);

        Assert.Equal(current.ExpiresAtUtc.AddMonths(1), _context.Subscription.ExpiresAtUtc);
        Assert.Equal(SubscriptionStatus.Expired, current.Status);
    }
}
