using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Abstractions.Ingestion;

public interface IDataIngestionJobRepository : IRepository<DataIngestionJob, Guid>
{
}

public interface IDataIngestionErrorRepository : IRepository<DataIngestionError, Guid>
{
}

public interface IIngestionScheduleRepository : IRepository<IngestionSchedule, Guid>
{
    /// <summary>The schedule for a source, tracked; null when the source has never been scheduled.</summary>
    Task<IngestionSchedule?> GetByPriceSourceIdAsync(Guid priceSourceId, CancellationToken cancellationToken = default);

    /// <summary>Ids of enabled schedules whose next run is at or before <paramref name="nowUtc"/>, oldest first.</summary>
    Task<IReadOnlyList<Guid>> GetDueIdsAsync(DateTimeOffset nowUtc, int limit, CancellationToken cancellationToken = default);
}
