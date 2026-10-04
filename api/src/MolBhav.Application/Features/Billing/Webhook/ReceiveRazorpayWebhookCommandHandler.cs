using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Billing.Webhook;

/// <summary>
/// Records an authenticated Razorpay webhook in the inbox and nothing else: no domain work happens on the request
/// path, so the 2xx goes back well inside Razorpay's 5 s timeout. A redelivery of an already-recorded event is a
/// success (Razorpay must stop sending it). A body without a readable event is acknowledged but not stored — there
/// is nothing a retry could do with it.
/// </summary>
internal sealed partial class ReceiveRazorpayWebhookCommandHandler(
    IWebhookInbox inbox,
    ILogger<ReceiveRazorpayWebhookCommandHandler> logger) : ICommandHandler<ReceiveRazorpayWebhookCommand>
{
    /// <summary>Matches the inbox <c>event_type</c> column; Razorpay event names are far shorter.</summary>
    private const int EventTypeMaxLength = 100;

    public async Task<Result> Handle(ReceiveRazorpayWebhookCommand request, CancellationToken cancellationToken)
    {
        if (!RazorpayWebhookPayload.TryParse(request.RawBody, out var parsed) || parsed.EventType.Length > EventTypeMaxLength)
        {
            LogUnreadable(logger, request.EventId);
            return Result.Success();
        }

        var isNew = await inbox.TryEnqueueAsync(
            RazorpayWebhookPayload.Provider, request.EventId, parsed.EventType, request.RawBody, cancellationToken);

        if (isNew)
        {
            LogQueued(logger, request.EventId, parsed.EventType, parsed.OrderId);
        }
        else
        {
            LogRedelivery(logger, request.EventId, parsed.EventType);
        }

        return Result.Success();
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay webhook {EventId} has a valid signature but no readable event; acknowledged, not stored.")]
    private static partial void LogUnreadable(ILogger logger, string eventId);

    [LoggerMessage(Level = LogLevel.Information, Message = "Razorpay webhook {EventId} ({EventType}) queued for order {OrderId}.")]
    private static partial void LogQueued(ILogger logger, string eventId, string eventType, string? orderId);

    [LoggerMessage(Level = LogLevel.Information, Message = "Razorpay webhook {EventId} ({EventType}) redelivered; already queued.")]
    private static partial void LogRedelivery(ILogger logger, string eventId, string eventType);
}
