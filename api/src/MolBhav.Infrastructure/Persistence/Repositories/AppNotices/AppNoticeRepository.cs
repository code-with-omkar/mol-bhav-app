using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.AppNotices;
using MolBhav.Domain.AppNotices;

namespace MolBhav.Infrastructure.Persistence.Repositories.AppNotices;

internal sealed class AppNoticeRepository(MolBhavDbContext dbContext)
    : Repository<AppNotice, Guid>(dbContext), IAppNoticeRepository
{
    // One row for the whole app; if a second ever appeared, the oldest stays the one in use.
    public Task<AppNotice?> GetCurrentAsync(CancellationToken cancellationToken = default) =>
        Set.OrderBy(n => n.CreatedAtUtc).FirstOrDefaultAsync(cancellationToken);
}
