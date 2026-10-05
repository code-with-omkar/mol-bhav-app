namespace MolBhav.Infrastructure.Authentication;

/// <summary>
/// Bound from <c>Authentication:Google</c>. Client ids are public identifiers (they ship inside the app), not secrets;
/// Google Sign-In on the device needs no client secret either.
/// <code>
/// "Authentication": { "Google": {
///   "Enabled": true,
///   "ServerClientId": "1234-web.apps.googleusercontent.com",
///   "AdditionalClientIds": [ "1234-ios.apps.googleusercontent.com" ] } }
/// </code>
/// </summary>
public sealed class GoogleSignInOptions
{
    public const string SectionName = "Authentication:Google";

    public bool Enabled { get; set; }

    /// <summary>The OAuth <i>Web application</i> client id. Android and web tokens are issued for it (their audience).</summary>
    public string? ServerClientId { get; set; }

    /// <summary>Other accepted audiences — the iOS client id (iOS tokens carry it as audience).</summary>
    public string[] AdditionalClientIds { get; set; } = [];

    /// <summary>Every client id a token may be issued for.</summary>
    public IReadOnlyList<string> Audiences =>
        [.. new[] { ServerClientId }.Concat(AdditionalClientIds).Where(id => !string.IsNullOrWhiteSpace(id)).Select(id => id!.Trim()).Distinct(StringComparer.Ordinal)];
}
