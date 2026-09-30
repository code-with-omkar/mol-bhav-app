using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Alerting.DeleteAlertRule;

public sealed record DeleteAlertRuleCommand(Guid AlertRuleId) : ICommand;
