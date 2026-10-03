using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.PasswordLogin;

internal sealed class LoginWithPasswordCommandHandler(
    ILoginMethods loginMethods,
    IUserRepository users,
    IRefreshTokenRepository refreshTokens,
    IPasswordHasher passwordHasher,
    IJwtTokenService jwtTokenService,
    TimeProvider timeProvider)
    : ICommandHandler<LoginWithPasswordCommand, PasswordLoginResponse>
{
    public async Task<Result<PasswordLoginResponse>> Handle(LoginWithPasswordCommand request, CancellationToken cancellationToken)
    {
        if (!loginMethods.PasswordEnabled)
        {
            return IdentityErrors.LoginMethodDisabled;
        }

        var phoneResult = PhoneNumber.Create(request.PhoneNumber);
        if (phoneResult.IsFailure)
        {
            return Result.Failure<PasswordLoginResponse>(phoneResult.Error);
        }

        var now = timeProvider.GetUtcNow();
        var user = await users.GetByPhoneNumberAsync(phoneResult.Value, cancellationToken);

        if (user is not null && user.IsPasswordLockedOut(now))
        {
            return new PasswordLoginResponse(PasswordLoginOutcome.LockedOut, null, user.PasswordLockoutEndsAtUtc);
        }

        // Always hash, even for an unknown number (null hash): equal cost on every path, no account enumeration by timing.
        var verification = passwordHasher.Verify(user?.PasswordHash, request.Password);

        if (user is null || verification == PasswordVerificationResult.Failed)
        {
            if (user is not null && user.HasPassword)
            {
                user.RecordFailedPasswordAttempt(now);
                if (user.IsPasswordLockedOut(now))
                {
                    return new PasswordLoginResponse(PasswordLoginOutcome.LockedOut, null, user.PasswordLockoutEndsAtUtc);
                }
            }

            return new PasswordLoginResponse(PasswordLoginOutcome.InvalidCredentials, null, null);
        }

        if (user.Status != UserStatus.Active)
        {
            return Error.Forbidden("User.Suspended", "This account has been suspended. Contact support.");
        }

        if (verification == PasswordVerificationResult.SuccessRehashNeeded)
        {
            user.SetPassword(passwordHasher.Hash(request.Password));
        }

        user.RecordLogin(now);

        var session = UserSessions.Issue(user, isNewUser: false, jwtTokenService, refreshTokens);
        return new PasswordLoginResponse(PasswordLoginOutcome.Succeeded, session, null);
    }
}
