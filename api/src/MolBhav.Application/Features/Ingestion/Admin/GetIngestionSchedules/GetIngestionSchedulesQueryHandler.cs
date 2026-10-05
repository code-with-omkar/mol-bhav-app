using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Ingestion.Admin.GetIngestionSchedules;

internal sealed class GetIngestionSchedulesQueryHandler(IIngestionReadService readService, ILanguageContext language)
    : IQueryHandler<GetIngestionSchedulesQuery, IReadOnlyList<AdminIngestionScheduleResponse>>
{
    public async Task<Result<IReadOnlyList<AdminIngestionScheduleResponse>>> Handle(GetIngestionSchedulesQuery request, CancellationToken cancellationToken)
    {
        string? categoryCode = null;
        if (!string.IsNullOrWhiteSpace(request.CategoryCode))
        {
            var code = ProcurementCategoryCode.Create(request.CategoryCode);
            if (code.IsFailure)
            {
                return Result.Failure<IReadOnlyList<AdminIngestionScheduleResponse>>(code.Error);
            }

            categoryCode = code.Value.Value;
        }

        var filter = new AdminIngestionScheduleFilter(
            categoryCode, new LanguagePreference(language.CurrentLanguage, language.DefaultLanguage));
        return Result.Success(await readService.GetAdminSchedulesAsync(filter, cancellationToken));
    }
}
