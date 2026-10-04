using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Features.Billing.Admin.ReplayWebhook;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.UnitTests.Billing;

public sealed class ReplayWebhookCommandHandlerTests
{
    private readonly IWebhookInbox _inbox = Substitute.For<IWebhookInbox>();
    private readonly ReplayWebhookCommandHandler _handler;

    public ReplayWebhookCommandHandlerTests()
    {
        _handler = new ReplayWebhookCommandHandler(
            _inbox, Substitute.For<ICurrentUser>(), NullLogger<ReplayWebhookCommandHandler>.Instance);
    }

    private async Task<Result> ReplayWith(WebhookRequeueResult outcome)
    {
        var id = Guid.NewGuid();
        _inbox.RequeueParkedAsync(id, Arg.Any<CancellationToken>()).Returns(outcome);
        return await _handler.Handle(new ReplayWebhookCommand(id), CancellationToken.None);
    }

    [Fact]
    public async Task Handle_Parked_Succeeds()
    {
        Assert.True((await ReplayWith(WebhookRequeueResult.Requeued)).IsSuccess);
    }

    [Fact]
    public async Task Handle_Unknown_IsNotFound()
    {
        Assert.Equal(BillingErrors.WebhookNotFound, (await ReplayWith(WebhookRequeueResult.NotFound)).Error);
    }

    [Fact]
    public async Task Handle_NotParked_IsConflict()
    {
        Assert.Equal(BillingErrors.WebhookNotParked, (await ReplayWith(WebhookRequeueResult.NotParked)).Error);
    }
}
