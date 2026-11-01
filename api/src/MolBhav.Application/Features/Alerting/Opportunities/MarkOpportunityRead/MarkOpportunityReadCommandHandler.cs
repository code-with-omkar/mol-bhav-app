using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Alerting.Opportunities.MarkOpportunityRead;

internal sealed class MarkOpportunityReadCommandHandler(IMarketOpportunityRepository opportunities, ICurrentUser currentUser)
    : ICommandHandler<MarkOpportunityReadCommand>
{
    public async Task<Result> Handle(MarkOpportunityReadCommand request, CancellationToken cancellationToken)
    {
        var opportunity = await opportunities.GetByIdAsync(request.OpportunityId, cancellationToken);
        if (opportunity is null || opportunity.UserId != currentUser.GetRequiredUserId())
        {
            return Error.NotFound("MarketOpportunity.NotFound", "Opportunity not found.");
        }

        opportunity.MarkRead();
        return Result.Success();
    }
}
