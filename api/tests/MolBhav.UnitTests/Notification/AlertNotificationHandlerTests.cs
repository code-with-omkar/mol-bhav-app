using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Features.Notification.SendAlertNotification;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Alerting.Events;
using MolBhav.Domain.Notification;
using MolBhav.Domain.Pricing;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Notification;

public sealed class AlertNotificationHandlerTests
{
    private readonly INotificationRepository _notifications = Substitute.For<INotificationRepository>();
    private readonly INotificationPreferencesRepository _preferences = Substitute.For<INotificationPreferencesRepository>();
    private readonly INotificationSender _sender = Substitute.For<INotificationSender>();
    private readonly IUnitOfWork _unitOfWork = Substitute.For<IUnitOfWork>();
    private readonly Guid _user = Guid.CreateVersion7();

    public AlertNotificationHandlerTests() =>
        _sender.SendAsync(Arg.Any<NotificationMessage>(), Arg.Any<CancellationToken>()).Returns(true);

    private AlertNotificationHandler CreateHandler() =>
        new(_notifications, _preferences, _sender, _unitOfWork, new FixedTimeProvider(DateTimeOffset.UnixEpoch));

    private AlertTriggeredDomainEvent Event() => new(
        Guid.CreateVersion7(), _user, Guid.CreateVersion7(), Guid.CreateVersion7(), null,
        LocationKind.Mandi, Guid.CreateVersion7(), null, 2000m, 2200m, 10m, AlertThresholdType.PriceChange);

    private void GivenPreferences(bool push, bool alertPush, bool whatsApp, bool alertWhatsApp)
    {
        var prefs = NotificationPreferences.CreateDefault(_user);
        prefs.Update(push, alertPush, priceUpdatePush: false, whatsApp, alertWhatsApp);
        _preferences.GetByUserIdAsync(_user, Arg.Any<CancellationToken>()).Returns(prefs);
    }

    [Fact]
    public async Task Sends_push_and_whatsapp_when_both_are_on_for_alerts()
    {
        GivenPreferences(push: true, alertPush: true, whatsApp: true, alertWhatsApp: true);

        await CreateHandler().HandleAsync(Event(), CancellationToken.None);

        await _sender.Received(1).SendAsync(
            Arg.Is<NotificationMessage>(n => n.Channel == NotificationChannel.Push), Arg.Any<CancellationToken>());
        await _sender.Received(1).SendAsync(
            Arg.Is<NotificationMessage>(n => n.Channel == NotificationChannel.WhatsApp), Arg.Any<CancellationToken>());
        _notifications.Received(2).Add(Arg.Any<NotificationMessage>());
        await _unitOfWork.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Skips_whatsapp_when_alert_whatsapp_is_off()
    {
        GivenPreferences(push: true, alertPush: true, whatsApp: true, alertWhatsApp: false);

        await CreateHandler().HandleAsync(Event(), CancellationToken.None);

        await _sender.DidNotReceive().SendAsync(
            Arg.Is<NotificationMessage>(n => n.Channel == NotificationChannel.WhatsApp), Arg.Any<CancellationToken>());
        _notifications.Received(1).Add(Arg.Any<NotificationMessage>());
    }

    [Fact]
    public async Task Without_saved_preferences_sends_push_only()
    {
        _preferences.GetByUserIdAsync(_user, Arg.Any<CancellationToken>()).Returns((NotificationPreferences?)null);

        await CreateHandler().HandleAsync(Event(), CancellationToken.None);

        await _sender.Received(1).SendAsync(
            Arg.Is<NotificationMessage>(n => n.Channel == NotificationChannel.Push), Arg.Any<CancellationToken>());
        await _sender.DidNotReceive().SendAsync(
            Arg.Is<NotificationMessage>(n => n.Channel == NotificationChannel.WhatsApp), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Sends_nothing_when_both_alert_channels_are_off()
    {
        GivenPreferences(push: true, alertPush: false, whatsApp: true, alertWhatsApp: false);

        await CreateHandler().HandleAsync(Event(), CancellationToken.None);

        await _sender.DidNotReceive().SendAsync(Arg.Any<NotificationMessage>(), Arg.Any<CancellationToken>());
        await _unitOfWork.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task A_failed_whatsapp_send_is_recorded_without_hiding_the_push()
    {
        GivenPreferences(push: true, alertPush: true, whatsApp: true, alertWhatsApp: true);
        _sender.SendAsync(
                Arg.Is<NotificationMessage>(n => n.Channel == NotificationChannel.WhatsApp), Arg.Any<CancellationToken>())
            .Returns(Task.FromException<bool>(new InvalidOperationException("template not approved")));
        var added = new List<NotificationMessage>();
        _notifications.Add(Arg.Do<NotificationMessage>(added.Add));

        await CreateHandler().HandleAsync(Event(), CancellationToken.None);

        Assert.Equal(NotificationStatus.Sent, added.Single(n => n.Channel == NotificationChannel.Push).Status);
        Assert.Equal(NotificationStatus.Failed, added.Single(n => n.Channel == NotificationChannel.WhatsApp).Status);
    }
}
