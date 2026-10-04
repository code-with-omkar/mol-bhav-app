using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Ingestion.Admin.GetIngestionSchedules;

internal sealed class GetIngestionSchedulesQueryHandler(IIngestionReadService readService)
    : IQueryHandler<GetIngestionSchedulesQuery, IReadOnlyList<AdminIngestionScheduleResponse>>
{
    public async Task<Result<IReadOnlyList<AdminIngestionScheduleResponse>>> Handle(GetIngestionSchedulesQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetAdminSchedulesAsync(cancellationToken));
}
