using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Identity;

/// <summary>Single mapping from a <see cref="User"/> to the claims placed in its access token (login and refresh must agree).</summary>
internal static class TokenSubjects
{
    private static readonly string[] UserRoles = [Roles.User];
    private static readonly string[] AdminRoles = [Roles.User, Roles.Admin];

    public static TokenSubject For(User user)
    {
        ArgumentNullException.ThrowIfNull(user);

        return new TokenSubject(
            user.Id,
            user.Role == UserRole.Admin ? AdminRoles : UserRoles,
            user.SubscriptionTier == SubscriptionTier.Pro ? SubscriptionTiers.Pro : SubscriptionTiers.Free,
            user.PreferredLanguage.Value);
    }
}
