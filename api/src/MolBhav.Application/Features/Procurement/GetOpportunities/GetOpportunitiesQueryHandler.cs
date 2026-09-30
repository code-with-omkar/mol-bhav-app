using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Features.Procurement.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Procurement.GetOpportunities;

internal sealed class GetOpportunitiesQueryHandler(IProcurementReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetOpportunitiesQuery, IReadOnlyList<ProcurementOpportunityResponse>>
{
    public async Task<Result<IReadOnlyList<ProcurementOpportunityResponse>>> Handle(GetOpportunitiesQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetOpportunitiesAsync(request.RequirementId, currentUser.GetRequiredUserId(), cancellationToken));
}
