using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Notification;

namespace MolBhav.Application.Features.Notification.RegisterDeviceToken;

internal sealed class RegisterDeviceTokenCommandHandler(
    IDeviceTokenRepository tokens,
    ICurrentUser currentUser)
    : ICommandHandler<RegisterDeviceTokenCommand>
{
    public async Task<Result> Handle(RegisterDeviceTokenCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();

        var exists = await tokens.ExistsAsync(userId, request.Token, cancellationToken);
        if (exists) return Result.Success();

        tokens.Add(DeviceToken.Create(userId, request.Token, request.Platform));
        return Result.Success();
    }
}
