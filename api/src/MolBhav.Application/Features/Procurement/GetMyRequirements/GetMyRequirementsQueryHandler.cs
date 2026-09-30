using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Features.Catalog;
using MolBhav.Application.Features.Procurement.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Procurement.GetMyRequirements;

internal sealed class GetMyRequirementsQueryHandler(IProcurementReadService readService, ICurrentUser currentUser, ILanguageContext languageContext)
    : IQueryHandler<GetMyRequirementsQuery, IReadOnlyList<ProcurementRequirementResponse>>
{
    public async Task<Result<IReadOnlyList<ProcurementRequirementResponse>>> Handle(GetMyRequirementsQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetMyRequirementsAsync(currentUser.GetRequiredUserId(), CatalogLanguage.From(languageContext), cancellationToken));
}
