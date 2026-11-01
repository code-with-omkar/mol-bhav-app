using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Admin.SetUserStatus;

internal sealed class SetUserStatusCommandHandler(IUserRepository users) : ICommandHandler<SetUserStatusCommand>
{
    public async Task<Result> Handle(SetUserStatusCommand request, CancellationToken cancellationToken)
    {
        if (request.UserId == request.ActingUserId)
        {
            return Error.Forbidden("User.CannotChangeOwnStatus", "You cannot change your own account's status.");
        }

        var user = await users.GetByIdAsync(request.UserId, cancellationToken);
        if (user is null)
        {
            return Error.NotFound("User.NotFound", "User not found.");
        }

        // Login, Google sign-in and token renewal all refuse a suspended user, so this is all it takes.
        return request.Action switch
        {
            UserStatusAction.Suspend => user.Suspend(),
            UserStatusAction.Reinstate => user.Reinstate(),
            _ => Error.Validation("User.ActionInvalid", "Unknown action."),
        };
    }
}
