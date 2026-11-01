using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Notification.RecordWhatsAppDeliveryStatus;

internal sealed class RecordWhatsAppDeliveryStatusCommandHandler(INotificationRepository notifications)
    : ICommandHandler<RecordWhatsAppDeliveryStatusCommand>
{
    public async Task<Result> Handle(RecordWhatsAppDeliveryStatusCommand request, CancellationToken cancellationToken)
    {
        var notification = await notifications.GetByProviderMessageIdAsync(request.ProviderMessageId, cancellationToken);

        // Unknown ids (another environment's message, or one sent before ids were stored) are not an error:
        // Meta must still get a 200 or it keeps retrying.
        if (notification is null)
        {
            return Result.Success();
        }

        if (request.State == WhatsAppDeliveryState.Delivered)
        {
            notification.MarkDelivered(request.At);
        }
        else
        {
            notification.MarkDeliveryFailed(request.Error ?? "WhatsApp reported a delivery failure.");
        }

        return Result.Success();
    }
}
