using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Alerting.MarkAlertRead;

internal sealed class MarkAlertReadCommandHandler(IAlertRepository alerts, ICurrentUser currentUser) : ICommandHandler<MarkAlertReadCommand>
{
    public async Task<Result> Handle(MarkAlertReadCommand request, CancellationToken cancellationToken)
    {
        var alert = await alerts.GetByIdAsync(request.AlertId, cancellationToken);
        if (alert is null || alert.UserId != currentUser.GetRequiredUserId())
        {
            return Error.NotFound("Alert.NotFound", "Alert not found.");
        }

        alert.MarkRead();
        return Result.Success();
    }
}
