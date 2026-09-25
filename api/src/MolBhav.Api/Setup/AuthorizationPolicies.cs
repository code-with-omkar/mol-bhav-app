namespace MolBhav.Api.Setup;

public static class AuthorizationPolicies
{
    public const string Admin = "admin";

    /// <summary>Pro-only features (CSV export, extended history, advanced alerts).</summary>
    public const string ProSubscriber = "pro-subscriber";
}
