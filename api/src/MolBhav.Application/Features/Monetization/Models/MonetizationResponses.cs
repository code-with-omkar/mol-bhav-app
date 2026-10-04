using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Features.Monetization.Models;

/// <summary>
/// What the signed-in user may do right now. The app reads it to label the "Watch ads or Go Pro" sheet; the API
/// enforces the same numbers independently, so a stale copy can never grant more than the rules allow.
/// </summary>
public sealed record EntitlementsResponse(
    bool IsPro,
    SlotEntitlementResponse Watchlist,
    SlotEntitlementResponse AlertRules,
    ReportEntitlementResponse PriceHistoryReports);

/// <param name="Used">Items in use.</param>
/// <param name="Limit">Current capacity; <c>null</c> = unlimited (Pro).</param>
/// <param name="Maximum">Highest capacity reachable with ads; <c>null</c> = unlimited (Pro).</param>
/// <param name="SlotsPerUnlock">Slots one unlock adds.</param>
/// <param name="AdsPerUnlock">Rewarded ads one unlock takes.</param>
/// <param name="CanUnlockWithAds">Whether watching ads would raise <paramref name="Limit"/> now.</param>
public sealed record SlotEntitlementResponse(
    int Used,
    int? Limit,
    int? Maximum,
    int SlotsPerUnlock,
    int AdsPerUnlock,
    bool CanUnlockWithAds);

/// <param name="AvailableUnlocks">Unused, unexpired report unlocks.</param>
/// <param name="UnlocksLeftToday">Further ad unlocks allowed today (IST).</param>
/// <param name="AdsPerUnlock">Rewarded ads one unlock takes.</param>
/// <param name="CanUnlockWithAds">Whether a new ad unlock may be started now.</param>
public sealed record ReportEntitlementResponse(
    int AvailableUnlocks,
    int UnlocksLeftToday,
    int AdsPerUnlock,
    bool CanUnlockWithAds);

public sealed record AdUnlockSessionResponse(
    Guid Id,
    MonetizedFeature Feature,
    int AdsRequired,
    int AdsVerified,
    AdUnlockSessionStatus Status,
    DateTimeOffset ExpiresAtUtc)
{
    public static AdUnlockSessionResponse From(AdUnlockSession session)
    {
        ArgumentNullException.ThrowIfNull(session);
        return new AdUnlockSessionResponse(
            session.Id, session.Feature, session.AdsRequired, session.AdsVerified, session.Status, session.ExpiresAtUtc);
    }
}
