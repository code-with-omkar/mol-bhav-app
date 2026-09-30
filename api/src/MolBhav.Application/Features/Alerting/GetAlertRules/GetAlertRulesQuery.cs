using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Alerting.Models;

namespace MolBhav.Application.Features.Alerting.GetAlertRules;

public sealed record GetAlertRulesQuery : IQuery<IReadOnlyList<AlertRuleResponse>>;
