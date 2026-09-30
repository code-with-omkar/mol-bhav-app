using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Alerting.UpdateAlertRule;

public sealed record UpdateAlertRuleCommand(Guid AlertRuleId, decimal? ThresholdPercent, decimal? ThresholdPrice, bool? IsActive) : ICommand;
