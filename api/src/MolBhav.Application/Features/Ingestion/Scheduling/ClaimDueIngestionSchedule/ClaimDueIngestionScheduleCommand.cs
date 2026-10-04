using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Ingestion.Scheduling.ClaimDueIngestionSchedule;

/// <summary>
/// Scheduler-internal: claims one due slot and advances the schedule to its next slot, in its own transaction.
/// Returns the price source to run, or null when the slot is no longer due (another instance claimed it first).
/// Two API instances racing on the same row are separated by the aggregate's <c>xmin</c> concurrency token.
/// </summary>
public sealed record ClaimDueIngestionScheduleCommand(Guid ScheduleId) : ICommand<Guid?>;
