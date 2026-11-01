using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.AppVersions;
using MolBhav.Domain.AppVersions;

namespace MolBhav.Infrastructure.Persistence.Repositories.AppVersions;

internal sealed class AppVersionPolicyRepository(MolBhavDbContext dbContext)
    : Repository<AppVersionPolicy, Guid>(dbContext), IAppVersionPolicyRepository
{
    // One row for the whole app; if a second ever appeared, the oldest stays the one in use.
    public Task<AppVersionPolicy?> GetCurrentAsync(CancellationToken cancellationToken = default) =>
        Set.OrderBy(p => p.CreatedAtUtc).FirstOrDefaultAsync(cancellationToken);
}
