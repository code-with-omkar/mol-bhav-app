using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Catalog.GetUnits;

internal sealed class GetUnitsQueryHandler(ICatalogReadService readService, ILanguageContext languageContext)
    : IQueryHandler<GetUnitsQuery, IReadOnlyList<UnitResponse>>
{
    public async Task<Result<IReadOnlyList<UnitResponse>>> Handle(GetUnitsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetUnitsAsync(CatalogLanguage.From(languageContext), cancellationToken));
}
