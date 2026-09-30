using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Domain.Support;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Support;

internal sealed class SupportTicketRepository(MolBhavDbContext dbContext)
    : Repository<SupportTicket, Guid>(dbContext), ISupportTicketRepository
{
    /// <summary>Loads the whole aggregate: the ticket plus its message thread.</summary>
    public override Task<SupportTicket?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Set.Include(t => t.Messages)
            .SingleOrDefaultAsync(t => t.Id == id, cancellationToken);
}
