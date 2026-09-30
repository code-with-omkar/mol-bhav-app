using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Notification;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Notification;

internal sealed class DeviceTokenRepository(MolBhavDbContext dbContext)
    : Repository<DeviceToken, Guid>(dbContext), IDeviceTokenRepository
{
    public Task<bool> ExistsAsync(Guid userId, string token, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(d => d.UserId == userId && d.Token == token, cancellationToken);

    public Task<List<string>> GetTokensByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Set.Where(d => d.UserId == userId).Select(d => d.Token).ToListAsync(cancellationToken);

    public async Task RemoveAsync(Guid userId, string token, CancellationToken cancellationToken = default)
    {
        var entity = await Set.FirstOrDefaultAsync(d => d.UserId == userId && d.Token == token, cancellationToken);
        if (entity is not null) Set.Remove(entity);
    }

    public async Task RemoveStaleAsync(IEnumerable<string> staleTokens, CancellationToken cancellationToken = default)
    {
        var tokenList = staleTokens.ToList();
        if (tokenList.Count == 0) return;

        await Set.Where(d => tokenList.Contains(d.Token)).ExecuteDeleteAsync(cancellationToken);
    }
}
