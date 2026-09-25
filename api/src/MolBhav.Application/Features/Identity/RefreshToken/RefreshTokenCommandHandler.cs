using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity.RefreshToken;

internal sealed class RefreshTokenCommandHandler(
    IRefreshTokenRepository refreshTokens,
    IUserRepository users,
    IJwtTokenService jwtTokenService,
    TimeProvider timeProvider)
    : ICommandHandler<RefreshTokenCommand, RefreshTokenResponse>
{
    public async Task<Result<RefreshTokenResponse>> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        var presentedHash = jwtTokenService.HashRefreshToken(request.RefreshToken);
        var grant = await refreshTokens.GetByTokenHashAsync(presentedHash, cancellationToken);

        if (grant is null)
        {
            return Error.Unauthorized("RefreshToken.Invalid", "The refresh token is invalid.");
        }

        var now = timeProvider.GetUtcNow();

        if (grant.WasJustRotated(now))
        {
            return new RefreshTokenResponse(RefreshTokenOutcome.Superseded, null, null, null, null, null);
        }

        // Reuse of an already-rotated-away token is a strong theft/replay signal (OWASP ASVS 3.3.1): shut the
        // whole family down. Committed as Result.Success — see VerifyOtpCommandHandler for why a "failed" login
        // attempt that still mutates real state must not be rolled back by UnitOfWorkBehavior.
        if (grant.RevokedAtUtc is not null)
        {
            var family = await refreshTokens.GetActiveFamilyAsync(grant.FamilyId, cancellationToken);
            foreach (var member in family)
            {
                member.Revoke(now);
            }

            return new RefreshTokenResponse(RefreshTokenOutcome.ReuseDetected, null, null, null, null, null);
        }

        if (now >= grant.ExpiresAtUtc)
        {
            return new RefreshTokenResponse(RefreshTokenOutcome.Expired, null, null, null, null, null);
        }

        var user = await users.GetByIdAsync(grant.UserId, cancellationToken);
        if (user is null || user.Status != UserStatus.Active)
        {
            return Error.Unauthorized("RefreshToken.UserUnavailable", "The account is no longer active.");
        }

        var newRefreshToken = jwtTokenService.CreateRefreshToken();
        var newGrant = RefreshTokenGrant.Rotate(grant, newRefreshToken.TokenHash, newRefreshToken.ExpiresAtUtc);
        refreshTokens.Add(newGrant);
        grant.Revoke(now, newGrant.Id);

        var accessToken = jwtTokenService.CreateAccessToken(TokenSubjects.For(user));

        return new RefreshTokenResponse(
            RefreshTokenOutcome.Rotated,
            user.Id,
            accessToken.Token,
            accessToken.ExpiresAtUtc,
            newRefreshToken.Token,
            newRefreshToken.ExpiresAtUtc);
    }
}
