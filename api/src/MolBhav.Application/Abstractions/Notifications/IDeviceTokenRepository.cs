using MolBhav.Domain.Notification;

namespace MolBhav.Application.Abstractions.Notifications;

public interface IDeviceTokenRepository
{
    Task<bool> ExistsAsync(Guid userId, string token, CancellationToken cancellationToken = default);

    /// <summary>All FCM/APNS tokens registered for a user — used when building a multicast message.</summary>
    Task<List<string>> GetTokensByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    void Add(DeviceToken token);

    /// <summary>Removes the token for the given user. No-op if it does not exist.</summary>
    Task RemoveAsync(Guid userId, string token, CancellationToken cancellationToken = default);

    /// <summary>Removes stale tokens across all users (called after FCM reports them as unregistered).</summary>
    Task RemoveStaleAsync(IEnumerable<string> staleTokens, CancellationToken cancellationToken = default);
}
