using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Persistence.Repositories.Ingestion;

internal sealed class DataIngestionErrorRepository(MolBhavDbContext dbContext)
    : Repository<DataIngestionError, Guid>(dbContext), IDataIngestionErrorRepository
{
}
