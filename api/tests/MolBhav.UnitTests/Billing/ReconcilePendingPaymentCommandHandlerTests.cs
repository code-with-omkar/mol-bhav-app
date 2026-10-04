using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Features.Billing.ReconcilePayments;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Identity;

namespace MolBhav.UnitTests.Billing;

public sealed class ReconcilePendingPaymentCommandHandlerTests
{
    private readonly ActivationTestContext _context = new();
    private readonly IPaymentGateway _gateway = Substitute.For<IPaymentGateway>();
    private readonly ReconcilePendingPaymentCommandHandler _handler;

    public ReconcilePendingPaymentCommandHandlerTests()
    {
        _context.Subscriptions.GetByIdAsync(_context.Subscription.Id, Arg.Any<CancellationToken>()).Returns(_context.Subscription);
        _handler = new ReconcilePendingPaymentCommandHandler(
            _context.Subscriptions, _gateway, _context.Activation, NullLogger<ReconcilePendingPaymentCommandHandler>.Instance);
    }

    private ReconcilePendingPaymentCommand Command => new(_context.Subscription.Id);

    private void GatewayReturns(params GatewayPayment[] payments) =>
        _gateway.GetOrderPaymentsAsync(_context.Subscription.RazorpayOrderId!, Arg.Any<CancellationToken>())
            .Returns(OrderPaymentsResult.Success(payments));

    private GatewayPayment Payment(string status, long? amountPaise = null, string id = "pay_1") =>
        new(id, amountPaise ?? _context.Subscription.ChargePaise, "INR", status);

    [Fact]
    public async Task Handle_CapturedPaymentForTheCharge_Activates()
    {
        GatewayReturns(Payment("failed", id: "pay_0"), Payment("captured"));

        var result = await _handler.Handle(Command, CancellationToken.None);

        Assert.Equal(PaymentReconciliationOutcome.Activated, result.Value);
        Assert.Equal(SubscriptionStatus.Active, _context.Subscription.Status);
        Assert.Equal("pay_1", _context.Subscription.RazorpayPaymentId);
        Assert.Equal(SubscriptionTier.Pro, _context.User.SubscriptionTier);
    }

    [Theory]
    [InlineData("created")]
    [InlineData("authorized")]
    [InlineData("failed")]
    [InlineData("refunded")]
    public async Task Handle_NoCapturedPayment_LeavesPending(string status)
    {
        GatewayReturns(Payment(status));

        var result = await _handler.Handle(Command, CancellationToken.None);

        Assert.Equal(PaymentReconciliationOutcome.NoCapturedPayment, result.Value);
        Assert.Equal(SubscriptionStatus.PendingPayment, _context.Subscription.Status);
    }

    [Fact]
    public async Task Handle_CapturedForAnotherAmount_DoesNotActivate()
    {
        GatewayReturns(Payment("captured", amountPaise: _context.Subscription.ChargePaise + 1));

        var result = await _handler.Handle(Command, CancellationToken.None);

        Assert.Equal(PaymentReconciliationOutcome.AmountMismatch, result.Value);
        Assert.Equal(SubscriptionStatus.PendingPayment, _context.Subscription.Status);
    }

    [Fact]
    public async Task Handle_GatewayUnavailable_FailsWithoutChanges()
    {
        _gateway.GetOrderPaymentsAsync(Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(OrderPaymentsResult.Failed("Gateway unreachable."));

        var result = await _handler.Handle(Command, CancellationToken.None);

        Assert.Equal(BillingErrors.GatewayUnavailable, result.Error);
        Assert.Equal(SubscriptionStatus.PendingPayment, _context.Subscription.Status);
    }

    [Fact]
    public async Task Handle_AlreadyActive_DoesNotCallTheGateway()
    {
        GatewayReturns(Payment("captured"));
        await _handler.Handle(Command, CancellationToken.None);
        _gateway.ClearReceivedCalls();

        var result = await _handler.Handle(Command, CancellationToken.None);

        Assert.Equal(PaymentReconciliationOutcome.NotPending, result.Value);
        await _gateway.DidNotReceive().GetOrderPaymentsAsync(Arg.Any<string>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_UnknownSubscription_IsNotPending()
    {
        var result = await _handler.Handle(new ReconcilePendingPaymentCommand(Guid.NewGuid()), CancellationToken.None);

        Assert.Equal(PaymentReconciliationOutcome.NotPending, result.Value);
    }
}
