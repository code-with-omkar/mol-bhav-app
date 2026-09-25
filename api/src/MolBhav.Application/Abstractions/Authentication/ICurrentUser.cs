namespace MolBhav.Application.Abstractions.Authentication;

/// <summary>The caller of the current request. Unauthenticated in background jobs.</summary>
public interface ICurrentUser
{
    bool IsAuthenticated { get; }

    Guid? UserId { get; }

    string? SubscriptionTier { get; }

    IReadOnlyCollection<string> Roles { get; }

    bool IsInRole(string role);

    /// <summary>Returns the user id or throws <see cref="UnauthorizedAccessException"/> — use only behind [Authorize].</summary>
    Guid GetRequiredUserId();
}
