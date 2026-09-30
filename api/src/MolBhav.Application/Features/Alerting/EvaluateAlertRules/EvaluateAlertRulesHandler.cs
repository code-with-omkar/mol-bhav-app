using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Events;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Pricing.Events;

namespace MolBhav.Application.Features.Alerting.EvaluateAlertRules;

/// <summary>
/// Reacts to every non-voided price recording: loads the product's active rules, matches each against the
/// recorded location (<see cref="AlertRule.Matches"/>), and — for a rule whose threshold the move crosses — creates
/// an <see cref="Alert"/> (which itself raises <c>AlertTriggeredDomainEvent</c> for Notification to pick up).
/// Runs outside <c>UnitOfWorkBehavior</c> (dispatched from the outbox, not through MediatR), so it commits its own
/// unit of work. Idempotent in effect: re-processing the same price record recomputes the same previous price and
/// would create a duplicate <see cref="Alert"/> row on redelivery, which is an acceptable at-least-once trade-off
/// for a notification-triggering side effect (a user sees the same alert twice, never a silently dropped one).
/// </summary>
internal sealed class EvaluateAlertRulesHandler(
    IAlertRuleRepository alertRules,
    IAlertRepository alerts,
    IPriceRecordRepository priceRecords,
    IUnitOfWork unitOfWork,
    TimeProvider timeProvider) : IDomainEventHandler<PriceRecordedDomainEvent>
{
    public async Task HandleAsync(PriceRecordedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var candidates = await alertRules.GetActiveByProductAsync(domainEvent.ProductId, cancellationToken);
        if (candidates.Count == 0)
        {
            return;
        }

        var matching = candidates
            .Where(r => r.Matches(domainEvent.ProductId, domainEvent.VariantId, domainEvent.LocationKind, domainEvent.MandiId, domainEvent.SupplierId))
            .ToArray();

        if (matching.Length == 0)
        {
            return;
        }

        var previous = await priceRecords.GetPreviousAsync(
            domainEvent.ProductId,
            domainEvent.VariantId,
            domainEvent.LocationKind,
            domainEvent.MandiId,
            domainEvent.SupplierId,
            domainEvent.RecordDate,
            domainEvent.PriceRecordId,
            cancellationToken);

        if (previous is null || previous.ModalPrice <= 0)
        {
            // No prior price to compare against — nothing to evaluate yet for this location.
            return;
        }

        var percentChange = (domainEvent.ModalPrice - previous.ModalPrice) / previous.ModalPrice * 100m;
        var triggeredAtUtc = timeProvider.GetUtcNow();
        var anyTriggered = false;

        foreach (var rule in matching)
        {
            if (!Crosses(rule, previous.ModalPrice, domainEvent.ModalPrice, percentChange))
            {
                continue;
            }

            var alert = Alert.Create(
                rule,
                domainEvent.PriceRecordId,
                domainEvent.LocationKind,
                domainEvent.MandiId,
                domainEvent.SupplierId,
                previous.ModalPrice,
                domainEvent.ModalPrice,
                percentChange,
                triggeredAtUtc);

            if (alert.IsFailure)
            {
                continue;
            }

            alerts.Add(alert.Value);
            anyTriggered = true;
        }

        if (anyTriggered)
        {
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }
    }

    /// <summary>
    /// Percent rules compare the move itself; price rules fire only when the new price crosses the level the previous
    /// price was still on the other side of, so a price that lingers past the threshold alerts once, not every day.
    /// </summary>
    private static bool Crosses(AlertRule rule, decimal previousModal, decimal newModal, decimal percentChange) => rule.ThresholdType switch
    {
        AlertThresholdType.PriceDrop => rule.ThresholdPercent is { } p && percentChange <= -p,
        AlertThresholdType.PriceSpike => rule.ThresholdPercent is { } p && percentChange >= p,
        AlertThresholdType.PriceBelow => rule.ThresholdPrice is { } p && newModal <= p && previousModal > p,
        AlertThresholdType.PriceAbove => rule.ThresholdPrice is { } p && newModal >= p && previousModal < p,
        _ => false,
    };
}
