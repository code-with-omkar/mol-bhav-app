namespace MolBhav.Application.Features.Identity.GetProfile;

/// <summary>
/// Profile screen. <c>BusinessType</c>/<c>State</c>/<c>District</c> are the stored values (kept for existing clients);
/// <c>StateId</c>/<c>DistrictId</c> are the matched market ids (null if none match) for preselecting the edit form;
/// <c>CategoryDetails</c> carries category names in the request language.
/// </summary>
public sealed record UserProfileResponse(
    Guid UserId,
    string PhoneNumberMasked,
    string? DisplayName,
    string PreferredLanguage,
    string SubscriptionTier,
    string? BusinessType,
    string? State,
    string? District,
    string? BusinessTypeCode,
    Guid? StateId,
    string? StateCode,
    string? StateName,
    Guid? DistrictId,
    string? DistrictName,
    IReadOnlyList<string> Categories,
    IReadOnlyList<ProfileCategoryResponse> CategoryDetails,
    bool PushEnabled,
    bool WhatsAppEnabled,
    DateTimeOffset? LastLoginAtUtc,
    DateTimeOffset MemberSinceUtc);

public sealed record ProfileCategoryResponse(string Code, string Name);
