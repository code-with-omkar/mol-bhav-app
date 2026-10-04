using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Features.Monetization.RecordRewardedAdView;

/// <summary>
/// The only path that turns watched ads into an unlock. Only a forged or unsigned callback fails (403); every
/// authentic one is acknowledged with success — a repeat, an AdMob console test, a late view for an expired session —
/// because AdMob treats a failure as "retry", and retrying an authentic callback would never change the outcome.
/// </summary>
internal sealed partial class RecordRewardedAdViewCommandHandler(
    IRewardedAdCallbackVerifier verifier,
    IRewardedAdViewRepository views,
    IAdUnlockSessionRepository sessions,
    IFeatureGrantRepository grants,
    IFreeTierPolicy policy,
    TimeProvider timeProvider,
    ILogger<RecordRewardedAdViewCommandHandler> logger) : ICommandHandler<RecordRewardedAdViewCommand>
{
    public async Task<Result> Handle(RecordRewardedAdViewCommand request, CancellationToken cancellationToken)
    {
        var callback = await verifier.VerifyAsync(request.RawQueryString, cancellationToken);
        if (callback is null)
        {
            LogRejected(logger);
            return MonetizationErrors.InvalidAdCallback;
        }

        if (await views.ExistsAsync(callback.TransactionId, cancellationToken))
        {
            return Result.Success();
        }

        if (!Guid.TryParse(callback.CustomData, out var sessionId) || !Guid.TryParse(callback.UserId, out var userId))
        {
            // AdMob's "verify callback URL" test and views shown without our options carry no session.
            LogUnmatched(logger, callback.TransactionId);
            return Result.Success();
        }

        var session = await sessions.GetByIdAsync(sessionId, cancellationToken);
        if (session is null || session.UserId != userId)
        {
            LogUnmatched(logger, callback.TransactionId);
            return Result.Success();
        }

        var now = timeProvider.GetUtcNow();
        var view = RewardedAdView.Record(callback.TransactionId, userId, sessionId, callback.AdNetwork, callback.AdUnit, now);
        if (view.IsFailure)
        {
            LogUnmatched(logger, callback.TransactionId);
            return Result.Success();
        }

        // The view is recorded even when the session can no longer use it: it was shown and paid for.
        views.Add(view.Value);

        var counted = session.RecordVerifiedAd(now);
        if (counted.IsFailure)
        {
            LogNotCounted(logger, session.Id, counted.Error.Code);
            return Result.Success();
        }

        if (counted.Value)
        {
            var grant = FeatureGrant.ForCompletedSession(session, policy.Limits, FeatureGrantSource.RewardedAds, now);
            if (grant.IsFailure)
            {
                return Result.Failure(grant.Error);
            }

            grants.Add(grant.Value);
            LogGranted(logger, session.Id, session.Feature);
        }

        return Result.Success();
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Rejected a rewarded-ad callback with an invalid signature")]
    private static partial void LogRejected(ILogger logger);

    [LoggerMessage(Level = LogLevel.Information, Message = "Rewarded-ad callback {TransactionId} matched no unlock session")]
    private static partial void LogUnmatched(ILogger logger, string transactionId);

    [LoggerMessage(Level = LogLevel.Information, Message = "Rewarded-ad view for session {SessionId} not counted: {Reason}")]
    private static partial void LogNotCounted(ILogger logger, Guid sessionId, string reason);

    [LoggerMessage(Level = LogLevel.Information, Message = "Unlock session {SessionId} granted {Feature}")]
    private static partial void LogGranted(ILogger logger, Guid sessionId, MonetizedFeature feature);
}
