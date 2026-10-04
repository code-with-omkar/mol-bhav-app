using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Monetization;

/// <summary>Stable error codes the app maps to the "Watch ads or Go Pro" sheet and its messages.</summary>
public static class MonetizationErrors
{
    public static readonly Error WatchlistLimitReached =
        Error.Forbidden("Entitlement.WatchlistLimitReached", "Your free watchlist is full. Watch an ad for more slots or go Pro.");

    public static readonly Error AlertRuleLimitReached =
        Error.Forbidden("Entitlement.AlertRuleLimitReached", "You have used your free alerts. Watch an ad for more or go Pro.");

    /// <summary>Kept identical to the code the app already handles for Pro-only reports.</summary>
    public static readonly Error ReportProRequired =
        Error.Forbidden("Report.ProRequired", "This report needs a Pro subscription, or unlock it by watching ads.");

    public static readonly Error UnlockNotNeeded =
        Error.Conflict("AdUnlock.NotNeeded", "Pro subscribers have no limits to unlock.");

    public static readonly Error UnlockLimitReached =
        Error.Forbidden("AdUnlock.LimitReached", "No more free unlocks are available. Go Pro for unlimited access.");

    public static readonly Error NoFillLimitReached =
        Error.Forbidden("AdUnlock.NoFillLimitReached", "No ads are available right now. Please try again later.");

    public static readonly Error SessionNotFound =
        Error.NotFound("AdUnlock.SessionNotFound", "Unlock session not found.");

    public static readonly Error SessionExpired =
        Error.BusinessRule("AdUnlock.SessionExpired", "This unlock has expired. Start again.");

    public static readonly Error SessionAlreadyGranted =
        Error.Conflict("AdUnlock.SessionAlreadyGranted", "This unlock has already been granted.");

    public static readonly Error GrantAlreadyConsumed =
        Error.Conflict("FeatureGrant.AlreadyConsumed", "This unlock has already been used.");

    public static readonly Error GrantExpired =
        Error.BusinessRule("FeatureGrant.Expired", "This unlock has expired.");

    public static readonly Error InvalidAdCallback =
        Error.Forbidden("AdMob.InvalidCallback", "The rewarded-ad callback could not be verified.");
}
