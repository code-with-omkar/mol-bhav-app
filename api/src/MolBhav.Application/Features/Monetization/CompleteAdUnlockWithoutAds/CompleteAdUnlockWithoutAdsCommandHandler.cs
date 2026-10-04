using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Application.Features.Monetization.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Features.Monetization.CompleteAdUnlockWithoutAds;

/// <summary>
/// The client reports "no fill", which the server cannot verify — so it is capped per user per day
/// (<see cref="FreeTierLimits.NoFillGrantsPerDay"/>), bounding what a dishonest client can gain.
/// </summary>
internal sealed class CompleteAdUnlockWithoutAdsCommandHandler(
    IAdUnlockSessionRepository sessions,
    IFeatureGrantRepository grants,
    IFreeTierPolicy policy,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : ICommandHandler<CompleteAdUnlockWithoutAdsCommand, AdUnlockSessionResponse>
{
    public async Task<Result<AdUnlockSessionResponse>> Handle(CompleteAdUnlockWithoutAdsCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var session = await sessions.GetByIdAsync(request.SessionId, cancellationToken);
        if (session is null || session.UserId != userId)
        {
            return MonetizationErrors.SessionNotFound;
        }

        var limits = policy.Limits;
        var now = timeProvider.GetUtcNow();

        var noFillToday = await grants.CountGrantedSinceAsync(
            userId, feature: null, FeatureGrantSource.NoFill, IndiaDay.StartUtc(now), cancellationToken);
        if (noFillToday >= limits.NoFillGrantsPerDay)
        {
            return MonetizationErrors.NoFillLimitReached;
        }

        var completed = session.CompleteWithoutAds(now);
        if (completed.IsFailure)
        {
            return Result.Failure<AdUnlockSessionResponse>(completed.Error);
        }

        var grant = FeatureGrant.ForCompletedSession(session, limits, FeatureGrantSource.NoFill, now);
        if (grant.IsFailure)
        {
            return Result.Failure<AdUnlockSessionResponse>(grant.Error);
        }

        grants.Add(grant.Value);
        return AdUnlockSessionResponse.From(session);
    }
}
