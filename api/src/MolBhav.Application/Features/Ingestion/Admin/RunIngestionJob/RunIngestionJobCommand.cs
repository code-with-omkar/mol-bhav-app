using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;

/// <summary>
/// <paramref name="TriggeredByUserId"/> is set for Manual runs (admin "Run now" or a backfill) and null for Scheduled ones.
/// <paramref name="AsOfDate"/> is the publication date to pull; null means <see cref="IngestionDates.DefaultAsOf"/> (yesterday, IST).
/// </summary>
public sealed record RunIngestionJobCommand(
    Guid PriceSourceId,
    IngestionTriggerType TriggerType,
    Guid? TriggeredByUserId,
    DateOnly? AsOfDate = null) : ICommand<CreatedResponse>;
