using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Alerting.UpdateAlertRule;

internal sealed class UpdateAlertRuleCommandHandler(IAlertRuleRepository alertRules, ICurrentUser currentUser) : ICommandHandler<UpdateAlertRuleCommand>
{
    public async Task<Result> Handle(UpdateAlertRuleCommand request, CancellationToken cancellationToken)
    {
        var rule = await alertRules.GetByIdAsync(request.AlertRuleId, cancellationToken);
        if (rule is null || rule.UserId != currentUser.GetRequiredUserId())
        {
            // Same 404 whether it's someone else's rule or doesn't exist — never reveal other users' data.
            return Error.NotFound("AlertRule.NotFound", "Alert rule not found.");
        }

        return rule.Update(request.ThresholdPercent, request.ThresholdPrice, request.IsActive!.Value);
    }
}
