using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Notification.UnregisterDeviceToken;

internal sealed class UnregisterDeviceTokenCommandHandler(
    IDeviceTokenRepository tokens,
    ICurrentUser currentUser)
    : ICommandHandler<UnregisterDeviceTokenCommand>
{
    public async Task<Result> Handle(UnregisterDeviceTokenCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        await tokens.RemoveAsync(userId, request.Token, cancellationToken);
        return Result.Success();
    }
}
