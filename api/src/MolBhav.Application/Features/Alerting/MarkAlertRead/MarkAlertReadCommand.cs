using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Alerting.MarkAlertRead;

public sealed record MarkAlertReadCommand(Guid AlertId) : ICommand;
