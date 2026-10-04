using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Admin.ReplayWebhook;

/// <summary>
/// Re-queues a parked webhook with a fresh attempt budget; the inbox processor picks it up on its next poll. Safe to
/// replay anything: webhook commands are idempotent and the amount check still applies. The replaying admin is
/// logged, since this can activate a paid subscription.
/// </summary>
internal sealed partial class ReplayWebhookCommandHandler(
    IWebhookInbox inbox,
    ICurrentUser currentUser,
    ILogger<ReplayWebhookCommandHandler> logger) : ICommandHandler<ReplayWebhookCommand>
{
    public async Task<Result> Handle(ReplayWebhookCommand request, CancellationToken cancellationToken)
    {
        var outcome = await inbox.RequeueParkedAsync(request.Id, cancellationToken);

        switch (outcome)
        {
            case WebhookRequeueResult.Requeued:
                LogReplayed(logger, request.Id, currentUser.UserId);
                return Result.Success();

            case WebhookRequeueResult.NotFound:
                return BillingErrors.WebhookNotFound;

            default:
                return BillingErrors.WebhookNotParked;
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Parked webhook {MessageId} re-queued by admin {AdminUserId}.")]
    private static partial void LogReplayed(ILogger logger, Guid messageId, Guid? adminUserId);
}
