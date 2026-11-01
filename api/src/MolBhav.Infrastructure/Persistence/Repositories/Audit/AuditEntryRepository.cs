using MolBhav.Application.Abstractions.Audit;
using MolBhav.Domain.Audit;

namespace MolBhav.Infrastructure.Persistence.Repositories.Audit;

internal sealed class AuditEntryRepository(MolBhavDbContext dbContext)
    : Repository<AuditEntry, Guid>(dbContext), IAuditEntryRepository
{
}
