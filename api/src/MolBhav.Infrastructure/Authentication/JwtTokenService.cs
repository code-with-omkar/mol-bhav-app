using System.Buffers.Text;
using System.Globalization;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using MolBhav.Application.Abstractions.Authentication;

namespace MolBhav.Infrastructure.Authentication;

internal sealed class JwtTokenService(IOptions<JwtOptions> options, TimeProvider timeProvider) : IJwtTokenService
{
    private const int RefreshTokenBytes = 64;

    private readonly JsonWebTokenHandler _handler = new() { SetDefaultTimesOnTokenCreation = false };

    public AccessToken CreateAccessToken(TokenSubject subject)
    {
        ArgumentNullException.ThrowIfNull(subject);

        var settings = options.Value;
        var now = timeProvider.GetUtcNow();
        var expiresAt = now.AddMinutes(settings.AccessTokenLifetimeMinutes);

        var claims = new List<Claim>
        {
            new(MolBhavClaimTypes.Subject, subject.UserId.ToString()),
            new(MolBhavClaimTypes.TokenId, Guid.NewGuid().ToString("N", CultureInfo.InvariantCulture)),
            new(MolBhavClaimTypes.SubscriptionTier, subject.SubscriptionTier),
            new(MolBhavClaimTypes.PreferredLanguage, subject.PreferredLanguage),
        };

        claims.AddRange(subject.Roles
            .Distinct(StringComparer.Ordinal)
            .Select(role => new Claim(MolBhavClaimTypes.Role, role)));

        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = settings.Issuer,
            Audience = settings.Audience,
            Subject = new ClaimsIdentity(claims),
            IssuedAt = now.UtcDateTime,
            NotBefore = now.UtcDateTime,
            Expires = expiresAt.UtcDateTime,
            SigningCredentials = new SigningCredentials(JwtSigningKey.Create(settings.SigningKey), JwtSigningKey.Algorithm),
        };

        return new AccessToken(_handler.CreateToken(descriptor), expiresAt);
    }

    public RefreshToken CreateRefreshToken()
    {
        var token = Base64Url.EncodeToString(RandomNumberGenerator.GetBytes(RefreshTokenBytes));
        var expiresAt = timeProvider.GetUtcNow().AddDays(options.Value.RefreshTokenLifetimeDays);

        return new RefreshToken(token, HashRefreshToken(token), expiresAt);
    }

    /// <summary>
    /// Unsalted SHA-256 is sufficient here: the input is 512 bits of CSPRNG output (not a password),
    /// so brute force/rainbow tables are infeasible, and a deterministic hash allows an indexed lookup.
    /// </summary>
    public string HashRefreshToken(string refreshToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(refreshToken);
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(refreshToken)));
    }
}
