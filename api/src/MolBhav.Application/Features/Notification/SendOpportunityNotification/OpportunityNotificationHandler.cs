using System.Globalization;
using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Events;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Alerting.Events;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification.SendOpportunityNotification;

/// <summary>Tells the user about a cheaper market (push and/or WhatsApp, per their alert switches). Runs from the
/// outbox like <c>AlertNotificationHandler</c>, so it commits its own unit of work.</summary>
internal sealed class OpportunityNotificationHandler(
    IMarketOpportunityReadService opportunities,
    INotificationRepository notifications,
    INotificationPreferencesRepository preferences,
    INotificationSender sender,
    IUnitOfWork unitOfWork,
    TimeProvider timeProvider) : IDomainEventHandler<MarketOpportunityFoundDomainEvent>
{
    public const string Title = "Buying opportunity";

    // Notifications go out in English, like price alerts.
    private static readonly LanguagePreference English = new("en", "en");

    public async Task HandleAsync(MarketOpportunityFoundDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var prefs = await preferences.GetByUserIdAsync(domainEvent.UserId, cancellationToken);
        var channels = AlertChannels.For(prefs);
        if (channels.Count == 0)
        {
            return;
        }

        var opportunity = await opportunities.GetOpportunityAsync(
            domainEvent.UserId, domainEvent.OpportunityId, English, cancellationToken);
        if (opportunity is null)
        {
            return;
        }

        var product = opportunity.VariantName is { Length: > 0 } variant
            ? $"{opportunity.Product.Name} ({variant})"
            : opportunity.Product.Name;
        var unit = opportunity.Product.DefaultUnit.Symbol;
        var best = opportunity.Best;
        var home = opportunity.Home;
        var body = string.Create(
            CultureInfo.InvariantCulture,
            $"{product}: Rs {best.Price:0.##}/{unit} at {best.Name}, about {opportunity.SavingsPercent:0.#}% (Rs {opportunity.SavingsPerUnit:0.##}/{unit}) cheaper after costs than {home.Name} (Rs {home.Price:0.##}).");

        foreach (var channel in channels)
        {
            var notification = NotificationMessage.Create(domainEvent.UserId, channel, Title, body);
            if (notification.IsFailure)
            {
                continue;
            }

            await DispatchAsync.SendAndMarkAsync(notification.Value, sender, timeProvider, cancellationToken);
            notifications.Add(notification.Value);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
