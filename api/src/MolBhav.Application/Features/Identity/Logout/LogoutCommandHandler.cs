using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Identity.Logout;

internal sealed class LogoutCommandHandler(
    IRefreshTokenRepository refreshTokens,
    IJwtTokenService jwtTokenService,
    ICurrentUser currentUser,
    TimeProvider timeProvider)
    : ICommandHandler<LogoutCommand>
{
    public async Task<Result> Handle(LogoutCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var presentedHash = jwtTokenService.HashRefreshToken(request.RefreshToken);
        var grant = await refreshTokens.GetByTokenHashAsync(presentedHash, cancellationToken);

        // A token that does not exist, belongs to someone else, or is already revoked: logging out is already the
        // end state, so this is a no-op success rather than an error the mobile app needs to handle specially.
        if (grant is not null && grant.UserId == userId)
        {
            grant.Revoke(timeProvider.GetUtcNow());
        }

        return Result.Success();
    }
}
