using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Weather.Models;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Weather.Admin.RunWeatherIngestionJob;

/// <summary>
/// Refreshes weather forecasts. <paramref name="UserId"/> null runs for every eligible user; a user id runs for that user
/// only. A <see cref="IngestionTriggerType.Scheduled"/> run skips users who already hold today's forecast (so restarts and
/// several API instances never repeat work); a <see cref="IngestionTriggerType.Manual"/> run always refetches.
/// </summary>
public sealed record RunWeatherIngestionJobCommand(Guid? UserId, IngestionTriggerType TriggerType) : ICommand<WeatherRunResponse>;
