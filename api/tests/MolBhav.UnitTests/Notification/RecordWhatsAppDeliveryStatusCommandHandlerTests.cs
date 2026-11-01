using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Features.Notification.RecordWhatsAppDeliveryStatus;
using MolBhav.Domain.Notification;

namespace MolBhav.UnitTests.Notification;

public sealed class RecordWhatsAppDeliveryStatusCommandHandlerTests
{
    private const string Wamid = "wamid.HBgM123";
    private static readonly DateTimeOffset At = new(2026, 10, 6, 12, 0, 0, TimeSpan.Zero);

    private readonly INotificationRepository _notifications = Substitute.For<INotificationRepository>();

    private RecordWhatsAppDeliveryStatusCommandHandler CreateHandler() => new(_notifications);

    private NotificationMessage GivenSentNotification()
    {
        var notification = NotificationMessage.Create(Guid.CreateVersion7(), NotificationChannel.WhatsApp, "Title", "Body").Value;
        notification.AttachProviderMessageId(Wamid);
        notification.MarkSent(At);
        _notifications.GetByProviderMessageIdAsync(Wamid, Arg.Any<CancellationToken>()).Returns(notification);
        return notification;
    }

    [Fact]
    public async Task Marks_the_notification_delivered_on_a_delivered_receipt()
    {
        var notification = GivenSentNotification();

        var result = await CreateHandler().Handle(
            new(Wamid, WhatsAppDeliveryState.Delivered, null, At), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(NotificationStatus.Delivered, notification.Status);
        Assert.Equal(At, notification.DeliveredAtUtc);
    }

    [Fact]
    public async Task Records_metas_error_when_delivery_fails_after_acceptance()
    {
        var notification = GivenSentNotification();

        await CreateHandler().Handle(
            new(Wamid, WhatsAppDeliveryState.Failed, "WhatsApp 131030: Recipient phone number not in allowed list", At),
            CancellationToken.None);

        Assert.Equal(NotificationStatus.Failed, notification.Status);
        Assert.Contains("131030", notification.FailureReason);
    }

    [Fact]
    public async Task A_late_delivered_receipt_does_not_undo_a_reported_failure()
    {
        var notification = GivenSentNotification();
        notification.MarkDeliveryFailed("WhatsApp 131026: Message undeliverable");

        await CreateHandler().Handle(new(Wamid, WhatsAppDeliveryState.Delivered, null, At), CancellationToken.None);

        Assert.Equal(NotificationStatus.Failed, notification.Status);
    }

    [Fact]
    public async Task Ignores_an_unknown_message_id_without_error()
    {
        _notifications.GetByProviderMessageIdAsync(Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns((NotificationMessage?)null);

        var result = await CreateHandler().Handle(
            new("wamid.unknown", WhatsAppDeliveryState.Delivered, null, At), CancellationToken.None);

        Assert.True(result.IsSuccess);
    }
}
