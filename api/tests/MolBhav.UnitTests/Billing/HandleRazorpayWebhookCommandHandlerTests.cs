using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Features.Billing.Webhook;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Identity;

namespace MolBhav.UnitTests.Billing;

public sealed class HandleRazorpayWebhookCommandHandlerTests
{
    private readonly ActivationTestContext _context = new(couponCode: "LAUNCH50");
    private readonly HandleRazorpayWebhookCommandHandler _handler;

    public HandleRazorpayWebhookCommandHandlerTests()
    {
        _handler = new HandleRazorpayWebhookCommandHandler(
            _context.Subscriptions, _context.Activation, NullLogger<HandleRazorpayWebhookCommandHandler>.Instance);
    }

    private HandleRazorpayWebhookCommand Captured(string eventType = HandleRazorpayWebhookCommandHandler.PaymentCaptured) =>
        new(eventType, _context.Subscription.RazorpayOrderId, "pay_1");

    [Theory]
    [InlineData(HandleRazorpayWebhookCommandHandler.PaymentCaptured)]
    [InlineData(HandleRazorpayWebhookCommandHandler.OrderPaid)]
    public async Task Handle_PaymentEvent_Activates(string eventType)
    {
        var result = await _handler.Handle(Captured(eventType), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(SubscriptionStatus.Active, _context.Subscription.Status);
        Assert.Null(_context.Subscription.RazorpaySignature);
        Assert.Equal(SubscriptionTier.Pro, _context.User.SubscriptionTier);
    }

    [Fact]
    public async Task Handle_Replay_IsANoOp()
    {
        await _handler.Handle(Captured(), CancellationToken.None);

        var replay = await _handler.Handle(Captured(HandleRazorpayWebhookCommandHandler.OrderPaid), CancellationToken.None);

        Assert.True(replay.IsSuccess);
        await _context.Coupons.Received(1).TryIncrementUsageAsync(Arg.Any<string>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_UnknownOrder_FailsAsNotFoundSoTheInboxRetries()
    {
        var result = await _handler.Handle(
            new HandleRazorpayWebhookCommand(HandleRazorpayWebhookCommandHandler.PaymentCaptured, "order_unknown", "pay_1"),
            CancellationToken.None);

        Assert.True(result.IsFailure);
        Assert.Equal(BillingErrors.SubscriptionNotFound, result.Error);
        Assert.Equal(SubscriptionStatus.PendingPayment, _context.Subscription.Status);
    }

    [Fact]
    public async Task Handle_PaymentFailed_LeavesSubscriptionPending()
    {
        var result = await _handler.Handle(Captured(HandleRazorpayWebhookCommandHandler.PaymentFailed), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(SubscriptionStatus.PendingPayment, _context.Subscription.Status);
    }

    [Fact]
    public async Task Handle_CouponCapReached_StillActivates()
    {
        _context.Coupons.TryIncrementUsageAsync(Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns(0);

        var result = await _handler.Handle(Captured(), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(SubscriptionStatus.Active, _context.Subscription.Status);
    }
}
