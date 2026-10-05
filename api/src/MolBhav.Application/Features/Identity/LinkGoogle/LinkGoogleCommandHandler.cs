using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity.LinkGoogle;

internal sealed class LinkGoogleCommandHandler(
    ILoginMethods loginMethods,
    IGoogleIdTokenVerifier verifier,
    IUserRepository users,
    ICurrentUser currentUser,
    TimeProvider timeProvider)
    : ICommandHandler<LinkGoogleCommand, LinkedGoogleResponse>
{
    public async Task<Result<LinkedGoogleResponse>> Handle(LinkGoogleCommand request, CancellationToken cancellationToken)
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

        var userId = currentUser.GetRequiredUserId();
        var owner = await users.GetByExternalLoginAsync(ExternalLoginProvider.Google, google.Subject, cancellationToken);
        if (owner is not null && owner.Id != userId)
        {
            return IdentityErrors.GoogleLinkedElsewhere;
        }

        var user = await users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return Error.NotFound("User.NotFound", "User not found.");
        }

        var linked = user.ExternalLogins.FirstOrDefault(l => l.Provider == ExternalLoginProvider.Google);
        if (linked is not null && linked.Subject != google.Subject)
        {
            return Error.Conflict("User.ExternalLoginAlreadyLinked", "A different Google account is already linked. Unlink it first.");
        }

        var email = google.EmailVerified ? google.Email : null;
        user.LinkExternalLogin(ExternalLoginProvider.Google, google.Subject, email, timeProvider.GetUtcNow());
        return new LinkedGoogleResponse(user.ExternalLogins.First(l => l.Provider == ExternalLoginProvider.Google).Email);
    }
}
