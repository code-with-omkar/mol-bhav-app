using Microsoft.AspNetCore.Authorization;
using MolBhav.Application.Abstractions.Authentication;

namespace MolBhav.Api.Setup;

internal static class AuthorizationSetup
{
    public static IServiceCollection AddApiAuthorization(this IServiceCollection services)
    {
        services.AddAuthorizationBuilder()
            // Secure by default: every endpoint requires a valid token unless it opts out with [AllowAnonymous].
            .SetFallbackPolicy(new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build())
            .AddPolicy(AuthorizationPolicies.Admin, policy => policy.RequireAuthenticatedUser().RequireRole(Roles.Admin))
            .AddPolicy(AuthorizationPolicies.ProSubscriber, policy => policy
                .RequireAuthenticatedUser()
                .RequireClaim(MolBhavClaimTypes.SubscriptionTier, SubscriptionTiers.Pro));

        return services;
    }
}
