using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Monetization.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Monetization.GetEntitlements;

internal sealed class GetEntitlementsQueryHandler(IEntitlementService entitlements)
    : IQueryHandler<GetEntitlementsQuery, EntitlementsResponse>
{
    public async Task<Result<EntitlementsResponse>> Handle(GetEntitlementsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await entitlements.GetAsync(cancellationToken));
}
