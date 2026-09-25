using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminUnits;

internal sealed class GetAdminUnitsQueryHandler(ICatalogReadService readService)
    : IQueryHandler<GetAdminUnitsQuery, IReadOnlyList<AdminUnitResponse>>
{
    public async Task<Result<IReadOnlyList<AdminUnitResponse>>> Handle(GetAdminUnitsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminUnitsAsync(cancellationToken));
}
