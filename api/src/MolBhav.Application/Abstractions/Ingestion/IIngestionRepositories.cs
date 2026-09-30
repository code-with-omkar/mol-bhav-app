using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Abstractions.Ingestion;

public interface IDataIngestionJobRepository : IRepository<DataIngestionJob, Guid>
{
}

public interface IDataIngestionErrorRepository : IRepository<DataIngestionError, Guid>
{
}
