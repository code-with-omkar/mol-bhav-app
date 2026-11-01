using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Admin.Models;

/// <summary>A user as the admin list shows them. The phone number is the account's identity, shown in full to admins only.</summary>
public sealed record AdminUserResponse(
    Guid Id,
    string PhoneNumber,
    string? DisplayName,
    UserRole Role,
    UserStatus Status,
    SubscriptionTier SubscriptionTier,
    string? State,
    string? District,
    string? BusinessType,
    DateTimeOffset? LastLoginAtUtc,
    DateTimeOffset CreatedAtUtc);

public sealed record AdminUserSubscriptionResponse(string PlanName, string Status, DateTimeOffset ExpiresAtUtc);

/// <summary>One user in full: the list fields plus what they picked and how much support they have used.</summary>
public sealed record AdminUserDetailResponse(
    AdminUserResponse User,
    IReadOnlyList<string> Categories,
    AdminUserSubscriptionResponse? LatestSubscription,
    int TicketsTotal,
    int TicketsOpen);

/// <summary>What an admin can do to an account's standing.</summary>
public enum UserStatusAction
{
    Suspend,
    Reinstate,
}
