namespace MolBhav.Application.Abstractions.Authentication;

/// <summary>
/// Short JWT claim names. Inbound claim mapping is disabled on the API so these arrive unchanged.
/// </summary>
public static class MolBhavClaimTypes
{
    public const string Subject = "sub";
    public const string TokenId = "jti";
    public const string Role = "role";
    public const string SubscriptionTier = "tier";
    public const string PreferredLanguage = "lang";
}
