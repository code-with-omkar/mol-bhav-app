using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.RegisterWithPassword;

internal sealed class RegisterWithPasswordCommandHandler(
    ILoginMethods loginMethods,
    IUserRepository users,
    IRefreshTokenRepository refreshTokens,
    IPasswordHasher passwordHasher,
    IJwtTokenService jwtTokenService,
    TimeProvider timeProvider)
    : ICommandHandler<RegisterWithPasswordCommand, LoginSessionResponse>
{
    public async Task<Result<LoginSessionResponse>> Handle(RegisterWithPasswordCommand request, CancellationToken cancellationToken)
    {
        if (!loginMethods.PasswordEnabled)
        {
            return IdentityErrors.LoginMethodDisabled;
        }

        var phoneResult = PhoneNumber.Create(request.PhoneNumber);
        if (phoneResult.IsFailure)
        {
            return Result.Failure<LoginSessionResponse>(phoneResult.Error);
        }

        var phone = phoneResult.Value;
        var now = timeProvider.GetUtcNow();
        var user = await users.GetByPhoneNumberAsync(phone, cancellationToken);
        var isNewUser = user is null;

        if (user is null)
        {
            user = User.RegisterWithPassword(phone, passwordHasher.Hash(request.Password));
            users.Add(user);
        }
        else if (!user.HasPassword && loginMethods.AllowClaimingPasswordlessAccounts)
        {
            if (user.Status != UserStatus.Active)
            {
                return Error.Forbidden("User.Suspended", "This account has been suspended. Contact support.");
            }

            user.SetPassword(passwordHasher.Hash(request.Password));
        }
        else
        {
            return IdentityErrors.AccountAlreadyExists;
        }

        user.RecordLogin(now);

        return UserSessions.Issue(user, isNewUser, jwtTokenService, refreshTokens);
    }
}
