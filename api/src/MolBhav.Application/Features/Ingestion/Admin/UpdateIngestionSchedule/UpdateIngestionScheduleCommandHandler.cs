using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.UpdateIngestionSchedule;

internal sealed class UpdateIngestionScheduleCommandHandler(
    IPriceSourceRepository sources,
    IIngestionScheduleRepository schedules,
    TimeProvider timeProvider) : ICommandHandler<UpdateIngestionScheduleCommand>
{
    public async Task<Result> Handle(UpdateIngestionScheduleCommand request, CancellationToken cancellationToken)
    {
        if (await sources.GetByIdAsync(request.PriceSourceId, cancellationToken) is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        // The validator guarantees these; the guard keeps the handler safe if it is ever called without it.
        if (request.IsEnabled is not { } isEnabled
            || request.Frequency is not { } frequency
            || !UpdateIngestionScheduleCommandValidator.TryParseTime(request.TimeOfDay, out var timeOfDay))
        {
            return Error.Validation("IngestionSchedule.Invalid", "isEnabled, frequency and timeOfDay (HH:mm) are required.");
        }

        var now = timeProvider.GetUtcNow();
        var schedule = await schedules.GetByPriceSourceIdAsync(request.PriceSourceId, cancellationToken);

        if (schedule is null)
        {
            var created = IngestionSchedule.Create(
                request.PriceSourceId, isEnabled, frequency, timeOfDay, request.DayOfWeek, request.IntervalHours, now);
            if (created.IsFailure)
            {
                return created.Error;
            }

            schedules.Add(created.Value);
            return Result.Success();
        }

        return schedule.Configure(isEnabled, frequency, timeOfDay, request.DayOfWeek, request.IntervalHours, now);
    }
}
