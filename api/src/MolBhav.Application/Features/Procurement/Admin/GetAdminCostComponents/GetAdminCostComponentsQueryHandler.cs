using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Features.Procurement.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Procurement.Admin.GetAdminCostComponents;

internal sealed class GetAdminCostComponentsQueryHandler(IProcurementReadService readService)
    : IQueryHandler<GetAdminCostComponentsQuery, IReadOnlyList<AdminCostComponentResponse>>
{
    public async Task<Result<IReadOnlyList<AdminCostComponentResponse>>> Handle(GetAdminCostComponentsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminCostComponentsAsync(cancellationToken));
}
