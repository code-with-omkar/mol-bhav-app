using MolBhav.Application.Abstractions.Catalog;

namespace MolBhav.Application.Abstractions.Identity;

/// <summary>Dapper-backed read side for the profile screen — declared here, implemented in Infrastructure, so SQL never leaks into Application.</summary>
public interface IUserProfileReadService
{
    Task<UserProfileReadModel?> GetByUserIdAsync(Guid userId, LanguagePreference language, CancellationToken cancellationToken = default);
}

public sealed record UserProfileReadModel(
    Guid UserId,
    string PhoneNumberMasked,
    string? DisplayName,
    string PreferredLanguage,
    string SubscriptionTier,
    string? BusinessType,
    string? State,
    string? District,
    Guid? StateId,
    string? StateCode,
    string? StateName,
    Guid? DistrictId,
    string? DistrictName,
    IReadOnlyList<string> Categories,
    IReadOnlyList<ProfileCategoryReadModel> CategoryDetails,
    bool PushEnabled,
    bool WhatsAppEnabled,
    DateTimeOffset? LastLoginAtUtc,
    DateTimeOffset CreatedAtUtc,
    bool HasPassword,
    bool HasGoogleLogin,
    string? GoogleEmail);

public sealed record ProfileCategoryReadModel(string Code, string Name);
