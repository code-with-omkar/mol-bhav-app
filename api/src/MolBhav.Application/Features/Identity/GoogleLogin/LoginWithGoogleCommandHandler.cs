using Microsoft.Extensions.Logging;
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
internal sealed partial class LoginWithGoogleCommandHandler(
    ILoginMethods loginMethods,
    IGoogleIdTokenVerifier verifier,
    IUserRepository users,
    IRefreshTokenRepository refreshTokens,
    IJwtTokenService jwtTokenService,
    TimeProvider timeProvider,
    ILogger<LoginWithGoogleCommandHandler> logger)
    : ICommandHandler<LoginWithGoogleCommand, LoginSessionResponse>
{
    public async Task<Result<LoginSessionResponse>> Handle(LoginWithGoogleCommand request, CancellationToken cancellationToken)
    {
        if (!loginMethods.GoogleEnabled)
        {
            LogRefused(logger, "Google sign-in is disabled (Authentication:Google:Enabled)");
            return IdentityErrors.LoginMethodDisabled;
        }

        var google = await verifier.VerifyAsync(request.IdToken, cancellationToken);
        if (google is null)
        {
            LogRefused(logger, "the Google ID token could not be verified (see the 'Google ID token rejected' line)");
            return IdentityErrors.GoogleTokenInvalid;
        }

        var now = timeProvider.GetUtcNow();
        var user = await users.GetByExternalLoginAsync(ExternalLoginProvider.Google, google.Subject, cancellationToken);

        if (user is not null)
        {
            if (user.Status != UserStatus.Active)
            {
                LogRefused(logger, "the linked account is not active");
                return IdentityErrors.Suspended;
            }

            user.RefreshExternalLoginEmail(ExternalLoginProvider.Google, google.EmailVerified ? google.Email : null);
            user.RecordLogin(now);
            return UserSessions.Issue(user, isNewUser: false, jwtTokenService, refreshTokens);
        }

        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            LogRefused(logger, "no MolBhav account is linked to this Google account yet; asking the app for a mobile number");
            return IdentityErrors.PhoneRequired;
        }

        var phone = PhoneNumber.Create(request.PhoneNumber);
        if (phone.IsFailure)
        {
            return Result.Failure<LoginSessionResponse>(phone.Error);
        }

        if (await users.GetByPhoneNumberAsync(phone.Value, cancellationToken) is not null)
        {
            LogRefused(logger, "that mobile number already has an account; log in with the password and use Link Google");
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

    [LoggerMessage(Level = LogLevel.Warning, Message = "Google sign-in refused: {Reason}.")]
    private static partial void LogRefused(ILogger logger, string reason);
}
