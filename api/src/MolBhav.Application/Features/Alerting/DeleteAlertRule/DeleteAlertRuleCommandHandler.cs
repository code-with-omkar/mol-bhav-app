using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Alerting.DeleteAlertRule;

internal sealed class DeleteAlertRuleCommandHandler(IAlertRuleRepository alertRules, ICurrentUser currentUser) : ICommandHandler<DeleteAlertRuleCommand>
{
    public async Task<Result> Handle(DeleteAlertRuleCommand request, CancellationToken cancellationToken)
    {
        var rule = await alertRules.GetByIdAsync(request.AlertRuleId, cancellationToken);
        if (rule is null || rule.UserId != currentUser.GetRequiredUserId())
        {
            return Error.NotFound("AlertRule.NotFound", "Alert rule not found.");
        }

        alertRules.Remove(rule);
        return Result.Success();
    }
}
