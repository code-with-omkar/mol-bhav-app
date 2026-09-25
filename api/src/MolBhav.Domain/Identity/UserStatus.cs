namespace MolBhav.Domain.Identity;

/// <summary>Account status. Suspension is an admin action (moderation/fraud); it is not user-initiated.</summary>
public enum UserStatus
{
    Active = 0,
    Suspended = 1,
}
