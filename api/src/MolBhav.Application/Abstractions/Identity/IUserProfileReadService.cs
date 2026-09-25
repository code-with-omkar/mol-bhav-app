namespace MolBhav.Application.Abstractions.Identity;

/// <summary>Dapper-backed read side for the profile screen — declared here, implemented in Infrastructure, so SQL never leaks into Application.</summary>
public interface IUserProfileReadService
{
    Task<UserProfileReadModel?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
}

public sealed record UserProfileReadModel(
    Guid UserId,
    string PhoneNumberMasked,
    string PreferredLanguage,
    string SubscriptionTier,
    string? BusinessType,
    string? State,
    string? District,
    IReadOnlyList<string> Categories,
    DateTimeOffset? LastLoginAtUtc,
    DateTimeOffset CreatedAtUtc);
