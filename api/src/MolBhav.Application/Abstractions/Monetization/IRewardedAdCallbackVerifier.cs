namespace MolBhav.Application.Abstractions.Monetization;

/// <summary>
/// A rewarded-ad server-side-verification callback whose signature checked out. <see cref="UserId"/> and
/// <see cref="CustomData"/> are what the app set on the ad before showing it; the signature proves AdMob sent them
/// for a real, completed view — not that the app chose them honestly, so they are cross-checked against the session.
/// </summary>
public sealed record RewardedAdCallback(
    string TransactionId,
    string? UserId,
    string? CustomData,
    string AdNetwork,
    string AdUnit,
    DateTimeOffset Timestamp);

public interface IRewardedAdCallbackVerifier
{
    /// <summary>
    /// Verifies the callback's ECDSA signature over its raw query string (without the leading <c>?</c>).
    /// Returns <c>null</c> when the signature, key or required parameters are missing or invalid.
    /// </summary>
    Task<RewardedAdCallback?> VerifyAsync(string rawQueryString, CancellationToken cancellationToken = default);
}
