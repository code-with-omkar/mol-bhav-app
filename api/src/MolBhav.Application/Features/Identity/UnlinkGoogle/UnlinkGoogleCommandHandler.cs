using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity.UnlinkGoogle;

internal sealed class UnlinkGoogleCommandHandler(IUserRepository users, ICurrentUser currentUser)
    : ICommandHandler<UnlinkGoogleCommand>
{
    public async Task<Result> Handle(UnlinkGoogleCommand request, CancellationToken cancellationToken)
    {
        var user = await users.GetByIdAsync(currentUser.GetRequiredUserId(), cancellationToken);
        if (user is null)
        {
            return Error.NotFound("User.NotFound", "User not found.");
        }

        if (!user.HasExternalLogin(ExternalLoginProvider.Google))
        {
            return Result.Success();
        }

        if (!user.HasPassword && user.ExternalLogins.Count == 1)
        {
            return Error.BusinessRule("User.LastSignInMethod", "Set a password before removing your only sign-in method.");
        }

        user.UnlinkExternalLogin(ExternalLoginProvider.Google);
        return Result.Success();
    }
}
