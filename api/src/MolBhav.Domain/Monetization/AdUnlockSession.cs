using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Monetization;

/// <summary>
/// One "watch N ads to unlock" offer the user accepted. Its id travels to AdMob as the rewarded ad's SSV
/// <c>custom_data</c>, so each signed callback can be matched back to it; only server-verified views count,
/// never the app's own "reward earned" event. Once <see cref="AdsRequired"/> views are verified the session is
/// <see cref="AdUnlockSessionStatus.Granted"/> and the caller issues the matching <see cref="FeatureGrant"/>.
/// </summary>
public sealed class AdUnlockSession : AggregateRoot<Guid>, IAuditableEntity
{
    private AdUnlockSession(Guid id, Guid userId, MonetizedFeature feature, int adsRequired, DateTimeOffset expiresAtUtc)
        : base(id)
    {
        UserId = userId;
        Feature = feature;
        AdsRequired = adsRequired;
        ExpiresAtUtc = expiresAtUtc;
        Status = AdUnlockSessionStatus.Pending;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private AdUnlockSession()
    {
    }

    public Guid UserId { get; private set; }

    public MonetizedFeature Feature { get; private set; }

    public int AdsRequired { get; private set; }

    public int AdsVerified { get; private set; }

    public AdUnlockSessionStatus Status { get; private set; }

    public DateTimeOffset ExpiresAtUtc { get; private set; }

    public DateTimeOffset? GrantedAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<AdUnlockSession> Start(
        Guid userId, MonetizedFeature feature, int adsRequired, DateTimeOffset nowUtc, TimeSpan lifetime)
    {
        if (userId == Guid.Empty)
        {
            return Error.Validation("AdUnlockSession.UserRequired", "User is required.");
        }

        if (!Enum.IsDefined(feature))
        {
            return Error.Validation("AdUnlockSession.FeatureInvalid", "Unknown feature.");
        }

        if (adsRequired < 1)
        {
            return Error.Validation("AdUnlockSession.AdsRequiredInvalid", "At least one ad is required.");
        }

        if (lifetime <= TimeSpan.Zero)
        {
            return Error.Validation("AdUnlockSession.LifetimeInvalid", "Lifetime must be positive.");
        }

        return new AdUnlockSession(Guid.CreateVersion7(), userId, feature, adsRequired, nowUtc + lifetime);
    }

    public bool IsOpen(DateTimeOffset nowUtc) => Status == AdUnlockSessionStatus.Pending && nowUtc < ExpiresAtUtc;

    /// <summary>
    /// Counts one server-verified ad view. Returns <c>true</c> when this view completed the unlock, so the caller
    /// issues the grant exactly once.
    /// </summary>
    public Result<bool> RecordVerifiedAd(DateTimeOffset nowUtc)
    {
        var open = EnsureOpen(nowUtc);
        if (open.IsFailure)
        {
            return Result.Failure<bool>(open.Error);
        }

        AdsVerified++;
        if (AdsVerified < AdsRequired)
        {
            return false;
        }

        Grant(nowUtc);
        return true;
    }

    /// <summary>
    /// Completes the unlock without (further) ads when no ad could be served, so users are not punished for
    /// missing inventory. The caller enforces the daily cap.
    /// </summary>
    public Result CompleteWithoutAds(DateTimeOffset nowUtc)
    {
        var open = EnsureOpen(nowUtc);
        if (open.IsFailure)
        {
            return open;
        }

        Grant(nowUtc);
        return Result.Success();
    }

    private Result EnsureOpen(DateTimeOffset nowUtc)
    {
        if (Status == AdUnlockSessionStatus.Granted)
        {
            return MonetizationErrors.SessionAlreadyGranted;
        }

        return nowUtc >= ExpiresAtUtc ? MonetizationErrors.SessionExpired : Result.Success();
    }

    private void Grant(DateTimeOffset nowUtc)
    {
        Status = AdUnlockSessionStatus.Granted;
        GrantedAtUtc = nowUtc;
    }
}
