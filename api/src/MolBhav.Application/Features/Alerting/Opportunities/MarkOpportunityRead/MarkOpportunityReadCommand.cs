using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Alerting.Opportunities.MarkOpportunityRead;

public sealed record MarkOpportunityReadCommand(Guid OpportunityId) : ICommand;
