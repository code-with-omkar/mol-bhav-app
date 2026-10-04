using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Ingestion.Scheduling.ClaimDueIngestionSchedule;

internal sealed class ClaimDueIngestionScheduleCommandHandler(
    IIngestionScheduleRepository schedules,
    TimeProvider timeProvider) : ICommandHandler<ClaimDueIngestionScheduleCommand, Guid?>
{
    public async Task<Result<Guid?>> Handle(ClaimDueIngestionScheduleCommand request, CancellationToken cancellationToken)
    {
        var schedule = await schedules.GetByIdAsync(request.ScheduleId, cancellationToken);
        if (schedule is null)
        {
            return Result.Success<Guid?>(null);
        }

        var now = timeProvider.GetUtcNow();
        if (!schedule.IsDue(now))
        {
            return Result.Success<Guid?>(null);
        }

        var dispatched = schedule.MarkDispatched(now);
        return dispatched.IsFailure
            ? Result.Failure<Guid?>(dispatched.Error)
            : Result.Success<Guid?>(schedule.PriceSourceId);
    }
}
