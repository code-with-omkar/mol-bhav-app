using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Application.Features.Monetization.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Features.Monetization.StartAdUnlock;

/// <summary>
/// Opens a "watch N ads" unlock after the user tapped the offer. The returned id is set as the rewarded ad's SSV
/// custom data, which is how AdMob's signed callbacks find their way back to this session.
/// </summary>
internal sealed class StartAdUnlockCommandHandler(
    IAdUnlockSessionRepository sessions,
    IEntitlementService entitlements,
    IFreeTierPolicy policy,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : ICommandHandler<StartAdUnlockCommand, AdUnlockSessionResponse>
{
    public async Task<Result<AdUnlockSessionResponse>> Handle(StartAdUnlockCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var feature = request.Feature!.Value;

        var allowed = await entitlements.EnsureCanStartUnlockAsync(feature, cancellationToken);
        if (allowed.IsFailure)
        {
            return Result.Failure<AdUnlockSessionResponse>(allowed.Error);
        }

        var limits = policy.Limits;
        var session = AdUnlockSession.Start(
            userId, feature, limits.AdsRequiredFor(feature), timeProvider.GetUtcNow(), limits.UnlockSessionLifetime);
        if (session.IsFailure)
        {
            return Result.Failure<AdUnlockSessionResponse>(session.Error);
        }

        sessions.Add(session.Value);
        return AdUnlockSessionResponse.From(session.Value);
    }
}
