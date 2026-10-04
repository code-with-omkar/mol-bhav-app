using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Monetization;

/// <summary>
/// An allowance a free user earned. Slot grants (<see cref="MonetizedFeature.WatchlistSlots"/>,
/// <see cref="MonetizedFeature.AlertRuleSlots"/>) never expire and are never consumed — their quantities add up to
/// extra capacity. Report grants allow exactly one report and expire after <see cref="ExpiresAtUtc"/>.
/// </summary>
public sealed class FeatureGrant : AggregateRoot<Guid>, IAuditableEntity
{
    private FeatureGrant(
        Guid id, Guid userId, MonetizedFeature feature, int quantity, FeatureGrantSource source, DateTimeOffset grantedAtUtc, DateTimeOffset? expiresAtUtc)
        : base(id)
    {
        UserId = userId;
        Feature = feature;
        Quantity = quantity;
        Source = source;
        GrantedAtUtc = grantedAtUtc;
        ExpiresAtUtc = expiresAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private FeatureGrant()
    {
    }

    public Guid UserId { get; private set; }

    public MonetizedFeature Feature { get; private set; }

    public int Quantity { get; private set; }

    public FeatureGrantSource Source { get; private set; }

    public DateTimeOffset GrantedAtUtc { get; private set; }

    public DateTimeOffset? ExpiresAtUtc { get; private set; }

    public DateTimeOffset? ConsumedAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<FeatureGrant> Create(
        Guid userId, MonetizedFeature feature, int quantity, FeatureGrantSource source, DateTimeOffset nowUtc, TimeSpan? lifetime)
    {
        if (userId == Guid.Empty)
        {
            return Error.Validation("FeatureGrant.UserRequired", "User is required.");
        }

        if (!Enum.IsDefined(feature) || !Enum.IsDefined(source))
        {
            return Error.Validation("FeatureGrant.Invalid", "Unknown feature or source.");
        }

        if (quantity < 1)
        {
            return Error.Validation("FeatureGrant.QuantityInvalid", "Quantity must be at least 1.");
        }

        if (lifetime is { } span && span <= TimeSpan.Zero)
        {
            return Error.Validation("FeatureGrant.LifetimeInvalid", "Lifetime must be positive.");
        }

        return new FeatureGrant(Guid.CreateVersion7(), userId, feature, quantity, source, nowUtc, nowUtc + lifetime);
    }

    /// <summary>The grant a completed <paramref name="session"/> is worth under <paramref name="limits"/>.</summary>
    public static Result<FeatureGrant> ForCompletedSession(
        AdUnlockSession session, FreeTierLimits limits, FeatureGrantSource source, DateTimeOffset nowUtc)
    {
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(limits);

        if (session.Status != AdUnlockSessionStatus.Granted)
        {
            return Error.BusinessRule("FeatureGrant.SessionNotGranted", "The unlock session has not been completed.");
        }

        var (quantity, lifetime) = limits.GrantTermsFor(session.Feature);
        return Create(session.UserId, session.Feature, quantity, source, nowUtc, lifetime);
    }

    public bool IsUsable(DateTimeOffset nowUtc) =>
        ConsumedAtUtc is null && (ExpiresAtUtc is null || nowUtc < ExpiresAtUtc);

    /// <summary>Uses a single-use grant (a report unlock). Slot grants are capacity, not consumables.</summary>
    public Result Consume(DateTimeOffset nowUtc)
    {
        if (FreeTierLimits.IsSlotFeature(Feature))
        {
            return Error.BusinessRule("FeatureGrant.NotConsumable", "Slot grants are not consumed.");
        }

        if (ConsumedAtUtc is not null)
        {
            return MonetizationErrors.GrantAlreadyConsumed;
        }

        if (ExpiresAtUtc is { } expires && nowUtc >= expires)
        {
            return MonetizationErrors.GrantExpired;
        }

        ConsumedAtUtc = nowUtc;
        return Result.Success();
    }
}
