using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity.LinkGoogle;

internal sealed partial class LinkGoogleCommandHandler(
    ILoginMethods loginMethods,
    IGoogleIdTokenVerifier verifier,
    IUserRepository users,
    ICurrentUser currentUser,
    TimeProvider timeProvider,
    ILogger<LinkGoogleCommandHandler> logger)
    : ICommandHandler<LinkGoogleCommand, LinkedGoogleResponse>
{
    public async Task<Result<LinkedGoogleResponse>> Handle(LinkGoogleCommand request, CancellationToken cancellationToken)
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

        var userId = currentUser.GetRequiredUserId();
        var owner = await users.GetByExternalLoginAsync(ExternalLoginProvider.Google, google.Subject, cancellationToken);
        if (owner is not null && owner.Id != userId)
        {
            LogRefused(logger, "this Google account is already linked to another user");
            return IdentityErrors.GoogleLinkedElsewhere;
        }

        var user = await users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            LogRefused(logger, "the signed-in user was not found (deleted or wrong database?)");
            return Error.NotFound("User.NotFound", "User not found.");
        }

        var linked = user.ExternalLogins.FirstOrDefault(l => l.Provider == ExternalLoginProvider.Google);
        if (linked is not null && linked.Subject != google.Subject)
        {
            LogRefused(logger, "a different Google account is already linked to this user");
            return Error.Conflict("User.ExternalLoginAlreadyLinked", "A different Google account is already linked. Unlink it first.");
        }

        var email = google.EmailVerified ? google.Email : null;
        user.LinkExternalLogin(ExternalLoginProvider.Google, google.Subject, email, timeProvider.GetUtcNow());
        LogLinked(logger, userId);
        return new LinkedGoogleResponse(user.ExternalLogins.First(l => l.Provider == ExternalLoginProvider.Google).Email);
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Link Google refused: {Reason}.")]
    private static partial void LogRefused(ILogger logger, string reason);

    [LoggerMessage(Level = LogLevel.Information, Message = "Link Google: login added for user {UserId}; saved when the request completes.")]
    private static partial void LogLinked(ILogger logger, Guid userId);
}
