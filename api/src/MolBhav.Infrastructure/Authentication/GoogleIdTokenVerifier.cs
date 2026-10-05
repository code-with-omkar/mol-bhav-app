using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using MolBhav.Application.Abstractions.Authentication;

namespace MolBhav.Infrastructure.Authentication;

/// <summary>
/// Validates Google ID tokens against Google's published OpenID configuration: RS256 signature with Google's rotating
/// keys (fetched and cached by <see cref="ConfigurationManager{T}"/>, refreshed on an unknown key id), issuer
/// <c>accounts.google.com</c>, our client ids as audience, and expiry (2 min clock skew). Singleton — the key cache is
/// shared across requests. No Google SDK dependency: the JWT stack already used for our own tokens does the work.
/// </summary>
internal sealed partial class GoogleIdTokenVerifier : IGoogleIdTokenVerifier
{
    public const string HttpClientName = "google-oidc";
    private const string Discovery = "https://accounts.google.com/.well-known/openid-configuration";

    private static readonly string[] Issuers = ["https://accounts.google.com", "accounts.google.com"];

    private readonly IOptions<GoogleSignInOptions> _options;
    private readonly ILogger<GoogleIdTokenVerifier> _logger;
    private readonly ConfigurationManager<OpenIdConnectConfiguration> _configuration;
    private readonly JsonWebTokenHandler _handler = new();

    public GoogleIdTokenVerifier(
        IHttpClientFactory httpClientFactory,
        IOptions<GoogleSignInOptions> options,
        ILogger<GoogleIdTokenVerifier> logger)
    {
        _options = options;
        _logger = logger;
        _configuration = new ConfigurationManager<OpenIdConnectConfiguration>(
            Discovery,
            new OpenIdConnectConfigurationRetriever(),
            new HttpDocumentRetriever(httpClientFactory.CreateClient(HttpClientName)) { RequireHttps = true });
    }

    public async Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default)
    {
        var audiences = _options.Value.Audiences;
        if (string.IsNullOrWhiteSpace(idToken) || audiences.Count == 0)
        {
            return null;
        }

        OpenIdConnectConfiguration configuration;
        try
        {
            configuration = await _configuration.GetConfigurationAsync(cancellationToken);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            LogDiscoveryFailed(_logger, ex);
            return null;
        }

        var parameters = new TokenValidationParameters
        {
            ValidIssuers = Issuers,
            ValidAudiences = audiences,
            IssuerSigningKeys = configuration.SigningKeys,
            ValidateIssuerSigningKey = true,
            RequireSignedTokens = true,
            RequireExpirationTime = true,
            ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
            ClockSkew = TimeSpan.FromMinutes(2),
        };

        var result = await _handler.ValidateTokenAsync(idToken, parameters);
        if (!result.IsValid && result.Exception is SecurityTokenSignatureKeyNotFoundException)
        {
            // Google rotated its keys since the last fetch: refresh once and retry.
            _configuration.RequestRefresh();
            parameters.IssuerSigningKeys = (await _configuration.GetConfigurationAsync(cancellationToken)).SigningKeys;
            result = await _handler.ValidateTokenAsync(idToken, parameters);
        }

        if (!result.IsValid)
        {
            // A plain local keeps CA1873 quiet (the analyzer flags expressions passed to log calls).
            var reason = result.Exception?.GetType().Name ?? "unknown";
            LogRejected(_logger, reason);
            return null;
        }

        var claims = result.Claims;
        var subject = claims.TryGetValue("sub", out var sub) ? sub?.ToString() : null;
        if (string.IsNullOrWhiteSpace(subject))
        {
            return null;
        }

        return new GoogleIdentity(
            subject,
            claims.TryGetValue("email", out var email) ? email?.ToString() : null,
            claims.TryGetValue("email_verified", out var verified) && IsTrue(verified),
            claims.TryGetValue("name", out var name) ? name?.ToString() : null);
    }

    private static bool IsTrue(object? value) => value switch
    {
        bool b => b,
        string s => bool.TryParse(s, out var parsed) && parsed,
        _ => false,
    };

    [LoggerMessage(Level = LogLevel.Warning, Message = "Google OpenID configuration could not be loaded")]
    private static partial void LogDiscoveryFailed(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Information, Message = "Google ID token rejected ({Reason})")]
    private static partial void LogRejected(ILogger logger, string reason);
}
