using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.GoogleLogin;

/// <summary>
/// Accounts are matched by Google's stable <c>sub</c> only — never by email or phone. A mobile number that already
/// belongs to an account is refused (409): linking Google to an existing account requires being signed in to it
/// (<c>LinkGoogleCommand</c>), otherwise anyone could attach their Google account to someone else's number.
/// </summary>
internal sealed class LoginWithGoogleCommandHandler(
    ILoginMethods loginMethods,
    IGoogleIdTokenVerifier verifier,
    IUserRepository users,
    IRefreshTokenRepository refreshTokens,
    IJwtTokenService jwtTokenService,
    TimeProvider timeProvider)
    : ICommandHandler<LoginWithGoogleCommand, LoginSessionResponse>
{
    public async Task<Result<LoginSessionResponse>> Handle(LoginWithGoogleCommand request, CancellationToken cancellationToken)
    {
        if (!loginMethods.GoogleEnabled)
        {
            return IdentityErrors.LoginMethodDisabled;
        }

        var google = await verifier.VerifyAsync(request.IdToken, cancellationToken);
        if (google is null)
        {
            return IdentityErrors.GoogleTokenInvalid;
        }

        var now = timeProvider.GetUtcNow();
        var user = await users.GetByExternalLoginAsync(ExternalLoginProvider.Google, google.Subject, cancellationToken);

        if (user is not null)
        {
            if (user.Status != UserStatus.Active)
            {
                return IdentityErrors.Suspended;
            }

            user.RefreshExternalLoginEmail(ExternalLoginProvider.Google, google.EmailVerified ? google.Email : null);
            user.RecordLogin(now);
            return UserSessions.Issue(user, isNewUser: false, jwtTokenService, refreshTokens);
        }

        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            return IdentityErrors.PhoneRequired;
        }

        var phone = PhoneNumber.Create(request.PhoneNumber);
        if (phone.IsFailure)
        {
            return Result.Failure<LoginSessionResponse>(phone.Error);
        }

        if (await users.GetByPhoneNumberAsync(phone.Value, cancellationToken) is not null)
        {
            return IdentityErrors.PhoneTakenForGoogle;
        }

        var created = User.RegisterWithExternalLogin(
            phone.Value,
            ExternalLoginProvider.Google,
            google.Subject,
            google.EmailVerified ? google.Email : null,
            google.Name,
            now);
        created.RecordLogin(now);
        users.Add(created);

        return UserSessions.Issue(created, isNewUser: true, jwtTokenService, refreshTokens);
    }
}
