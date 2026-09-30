using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Persistence.Repositories.Ingestion;

internal sealed class DataIngestionJobRepository(MolBhavDbContext dbContext)
    : Repository<DataIngestionJob, Guid>(dbContext), IDataIngestionJobRepository
{
}
