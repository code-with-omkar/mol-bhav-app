using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Features.Notification.Admin.SendTestOpsAlert;

namespace MolBhav.UnitTests.Billing;

public sealed class SendTestOpsAlertCommandHandlerTests
{
    private readonly IOpsAlertSender _sender = Substitute.For<IOpsAlertSender>();
    private readonly SendTestOpsAlertCommandHandler _handler;

    public SendTestOpsAlertCommandHandlerTests()
    {
        _sender.Channel.Returns("slack");
        _handler = new SendTestOpsAlertCommandHandler(
            _sender, Substitute.For<ICurrentUser>(), new FixedTimeProvider(BillingTestData.Now),
            NullLogger<SendTestOpsAlertCommandHandler>.Instance);
    }

    [Fact]
    public async Task Handle_Delivered_ReturnsTheChannel()
    {
        _sender.SendAsync(Arg.Any<OpsAlert>(), Arg.Any<CancellationToken>()).Returns(true);

        var result = await _handler.Handle(new SendTestOpsAlertCommand(), CancellationToken.None);

        Assert.Equal(new OpsAlertTestResponse("slack", BillingTestData.Now), result.Value);
        await _sender.Received(1).SendAsync(Arg.Is<OpsAlert>(a => a.Title.StartsWith("Test alert", StringComparison.Ordinal)), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_NotDelivered_FailsSoTheAdminSeesTheChannelIsBroken()
    {
        _sender.SendAsync(Arg.Any<OpsAlert>(), Arg.Any<CancellationToken>()).Returns(false);

        var result = await _handler.Handle(new SendTestOpsAlertCommand(), CancellationToken.None);

        Assert.Equal(SendTestOpsAlertCommandHandler.DeliveryFailed, result.Error);
    }
}
