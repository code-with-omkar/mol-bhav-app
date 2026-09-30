using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;

/// <summary><paramref name="TriggeredByUserId"/> is set by the admin controller (Manual) or left null by the scheduler (Scheduled).</summary>
public sealed record RunIngestionJobCommand(Guid PriceSourceId, IngestionTriggerType TriggerType, Guid? TriggeredByUserId) : ICommand<CreatedResponse>;
