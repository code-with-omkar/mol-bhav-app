using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Identity.ChangePassword;

internal sealed class ChangePasswordCommandHandler(
    IUserRepository users,
    ICurrentUser currentUser,
    IPasswordHasher passwordHasher,
    IRefreshTokenRepository refreshTokens,
    TimeProvider timeProvider)
    : ICommandHandler<ChangePasswordCommand>
{
    public async Task<Result> Handle(ChangePasswordCommand request, CancellationToken cancellationToken)
    {
        var user = await users.GetByIdAsync(currentUser.GetRequiredUserId(), cancellationToken);
        if (user is null)
        {
            return Error.NotFound("User.NotFound", "User not found.");
        }

        if (user.HasPassword)
        {
            var verification = passwordHasher.Verify(user.PasswordHash, request.CurrentPassword ?? string.Empty);
            if (verification == PasswordVerificationResult.Failed)
            {
                return Error.Validation("Password.CurrentIncorrect", "The current password is incorrect.");
            }
        }

        user.SetPassword(passwordHasher.Hash(request.NewPassword));

        // A new password ends every session, this device included: the app signs in again with it. An access token
        // already issued works until it expires (15 minutes).
        var now = timeProvider.GetUtcNow();
        foreach (var grant in await refreshTokens.GetActiveForUserAsync(user.Id, cancellationToken))
        {
            grant.Revoke(now);
        }

        return Result.Success();
    }
}
