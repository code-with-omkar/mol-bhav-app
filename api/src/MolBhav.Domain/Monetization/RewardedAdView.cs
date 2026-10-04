using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Monetization;

/// <summary>
/// One rewarded-ad view confirmed by AdMob's signed server-side-verification callback. AdMob's
/// <see cref="TransactionId"/> is unique per view, so a repeated callback is recognised and ignored.
/// Immutable once written: an audit trail of what was paid for, not a working record.
/// </summary>
public sealed class RewardedAdView : AggregateRoot<Guid>
{
    public const int TransactionIdMaxLength = 128;
    public const int AdNetworkMaxLength = 32;
    public const int AdUnitMaxLength = 64;

    private RewardedAdView(Guid id, string transactionId, Guid userId, Guid sessionId, string adNetwork, string adUnit, DateTimeOffset verifiedAtUtc)
        : base(id)
    {
        TransactionId = transactionId;
        UserId = userId;
        SessionId = sessionId;
        AdNetwork = adNetwork;
        AdUnit = adUnit;
        VerifiedAtUtc = verifiedAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private RewardedAdView()
    {
        TransactionId = string.Empty;
        AdNetwork = string.Empty;
        AdUnit = string.Empty;
    }

    public string TransactionId { get; private set; }

    public Guid UserId { get; private set; }

    public Guid SessionId { get; private set; }

    /// <summary>AdMob's ad-source id (which network filled the impression).</summary>
    public string AdNetwork { get; private set; }

    public string AdUnit { get; private set; }

    public DateTimeOffset VerifiedAtUtc { get; private set; }

    public static Result<RewardedAdView> Record(
        string transactionId, Guid userId, Guid sessionId, string adNetwork, string adUnit, DateTimeOffset verifiedAtUtc)
    {
        if (string.IsNullOrWhiteSpace(transactionId) || transactionId.Length > TransactionIdMaxLength)
        {
            return Error.Validation("RewardedAdView.TransactionIdInvalid", "Transaction id is missing or too long.");
        }

        if (userId == Guid.Empty || sessionId == Guid.Empty)
        {
            return Error.Validation("RewardedAdView.ReferenceRequired", "User and session are required.");
        }

        return new RewardedAdView(
            Guid.CreateVersion7(),
            transactionId,
            userId,
            sessionId,
            Truncate(adNetwork, AdNetworkMaxLength),
            Truncate(adUnit, AdUnitMaxLength),
            verifiedAtUtc);
    }

    private static string Truncate(string? value, int maxLength) =>
        string.IsNullOrEmpty(value) ? string.Empty : value.Length <= maxLength ? value : value[..maxLength];
}
