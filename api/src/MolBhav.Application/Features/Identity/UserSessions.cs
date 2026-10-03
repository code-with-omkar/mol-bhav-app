using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity;

/// <summary>Issues the access token and the initial refresh-token grant for a user who has just proven a credential.</summary>
internal static class UserSessions
{
    public static LoginSessionResponse Issue(
        User user,
        bool isNewUser,
        IJwtTokenService jwtTokenService,
        IRefreshTokenRepository refreshTokens)
    {
        ArgumentNullException.ThrowIfNull(user);
        ArgumentNullException.ThrowIfNull(jwtTokenService);
        ArgumentNullException.ThrowIfNull(refreshTokens);

        var accessToken = jwtTokenService.CreateAccessToken(TokenSubjects.For(user));
        var refreshToken = jwtTokenService.CreateRefreshToken();
        refreshTokens.Add(RefreshTokenGrant.IssueInitial(user.Id, refreshToken.TokenHash, refreshToken.ExpiresAtUtc));

        return new LoginSessionResponse(
            user.Id,
            accessToken.Token,
            accessToken.ExpiresAtUtc,
            refreshToken.Token,
            refreshToken.ExpiresAtUtc,
            isNewUser,
            user.IsOnboarded);
    }
}
