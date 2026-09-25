using System.Security.Claims;
using MolBhav.Application.Abstractions.Authentication;

namespace MolBhav.Api.Services;

internal sealed class CurrentUser(IHttpContextAccessor httpContextAccessor) : ICurrentUser
{
    private ClaimsPrincipal? Principal => httpContextAccessor.HttpContext?.User;

    public bool IsAuthenticated => Principal?.Identity?.IsAuthenticated == true;

    public Guid? UserId =>
        IsAuthenticated && Guid.TryParse(Principal!.FindFirst(MolBhavClaimTypes.Subject)?.Value, out var userId)
            ? userId
            : null;

    public string? SubscriptionTier => Principal?.FindFirst(MolBhavClaimTypes.SubscriptionTier)?.Value;

    public IReadOnlyCollection<string> Roles =>
        Principal?.FindAll(MolBhavClaimTypes.Role).Select(claim => claim.Value).ToArray() ?? [];

    public bool IsInRole(string role) => Principal?.IsInRole(role) == true;

    public Guid GetRequiredUserId() =>
        UserId ?? throw new UnauthorizedAccessException("An authenticated user is required for this operation.");
}
