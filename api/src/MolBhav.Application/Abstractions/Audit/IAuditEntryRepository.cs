using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Audit;

namespace MolBhav.Application.Abstractions.Audit;

public interface IAuditEntryRepository : IRepository<AuditEntry, Guid>
{
}
