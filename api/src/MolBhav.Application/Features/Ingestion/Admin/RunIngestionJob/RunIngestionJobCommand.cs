using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;

/// <summary>
/// <paramref name="TriggeredByUserId"/> is set for Manual runs (admin "Run now" or a backfill) and null for Scheduled ones.
/// <paramref name="AsOfDate"/> is the publication date to pull; null means <see cref="IngestionDates.DefaultAsOf"/> (yesterday, IST).
/// <paramref name="States"/>, <paramref name="Commodities"/> and <paramref name="Markets"/> narrow a manual run to those names
/// (exact source spelling; null/empty = all). Scheduled runs and backfills leave them empty and pull everything.
/// </summary>
public sealed record RunIngestionJobCommand(
    Guid PriceSourceId,
    IngestionTriggerType TriggerType,
    Guid? TriggeredByUserId,
    DateOnly? AsOfDate = null,
    IReadOnlyList<string>? States = null,
    IReadOnlyList<string>? Commodities = null,
    IReadOnlyList<string>? Markets = null) : ICommand<CreatedResponse>, IAuditedCommand
{
    // Scheduled and background runs have no signed-in user, so only an admin's "Run now" is recorded.
    string IAuditedCommand.AuditAction => "Ingestion.Run";

    string? IAuditedCommand.AuditTarget => PriceSourceId.ToString();

    string IAuditedCommand.AuditSummary =>
        States is { Count: > 0 } || Commodities is { Count: > 0 } || Markets is { Count: > 0 }
            ? "Started a filtered price pull"
            : "Started a full price pull";
}
