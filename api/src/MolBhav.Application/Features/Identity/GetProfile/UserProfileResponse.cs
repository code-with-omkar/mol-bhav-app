namespace MolBhav.Application.Features.Identity.GetProfile;

public sealed record UserProfileResponse(
    Guid UserId,
    string PhoneNumberMasked,
    string PreferredLanguage,
    string SubscriptionTier,
    string? BusinessType,
    string? State,
    string? District,
    IReadOnlyList<string> Categories,
    DateTimeOffset? LastLoginAtUtc,
    DateTimeOffset MemberSinceUtc);
