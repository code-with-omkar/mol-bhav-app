using System.Globalization;
using System.Security.Cryptography;
using MolBhav.Application.Abstractions.Authentication;

namespace MolBhav.Infrastructure.Authentication;

/// <summary>
/// PBKDF2-HMAC-SHA256 with a 128-bit random salt and OWASP's 2023 work factor (600,000 iterations). Built on the BCL
/// (<see cref="Rfc2898DeriveBytes.Pbkdf2(string, byte[], int, HashAlgorithmName, int)"/>), so no extra package.
/// Stored format: <c>pbkdf2-sha256$&lt;iterations&gt;$&lt;salt b64&gt;$&lt;digest b64&gt;</c> — self-describing, so the
/// work factor can be raised later and old hashes upgraded on the next successful login.
/// </summary>
internal sealed class Pbkdf2PasswordHasher : IPasswordHasher
{
    public const int Iterations = 600_000;

    private const string Algorithm = "pbkdf2-sha256";
    private const int SaltBytes = 16;
    private const int DigestBytes = 32;
    private const char Separator = '$';

    private static readonly HashAlgorithmName Prf = HashAlgorithmName.SHA256;

    /// <summary>Burned on unknown accounts so they cost the same as known ones.</summary>
    private static readonly byte[] DummySalt = RandomNumberGenerator.GetBytes(SaltBytes);

    public string Hash(string password)
    {
        ArgumentNullException.ThrowIfNull(password);

        var salt = RandomNumberGenerator.GetBytes(SaltBytes);
        var digest = Rfc2898DeriveBytes.Pbkdf2(password, salt, Iterations, Prf, DigestBytes);

        return string.Join(
            Separator,
            Algorithm,
            Iterations.ToString(CultureInfo.InvariantCulture),
            Convert.ToBase64String(salt),
            Convert.ToBase64String(digest));
    }

    public PasswordVerificationResult Verify(string? passwordHash, string password)
    {
        ArgumentNullException.ThrowIfNull(password);

        if (!TryParse(passwordHash, out var iterations, out var salt, out var expected))
        {
            _ = Rfc2898DeriveBytes.Pbkdf2(password, DummySalt, Iterations, Prf, DigestBytes);
            return PasswordVerificationResult.Failed;
        }

        var actual = Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations, Prf, expected.Length);
        if (!CryptographicOperations.FixedTimeEquals(actual, expected))
        {
            return PasswordVerificationResult.Failed;
        }

        return iterations < Iterations ? PasswordVerificationResult.SuccessRehashNeeded : PasswordVerificationResult.Success;
    }

    private static bool TryParse(string? value, out int iterations, out byte[] salt, out byte[] digest)
    {
        iterations = 0;
        salt = [];
        digest = [];

        if (string.IsNullOrEmpty(value))
        {
            return false;
        }

        var parts = value.Split(Separator);
        if (parts.Length != 4
            || !string.Equals(parts[0], Algorithm, StringComparison.Ordinal)
            || !int.TryParse(parts[1], NumberStyles.None, CultureInfo.InvariantCulture, out iterations)
            || iterations <= 0)
        {
            return false;
        }

        try
        {
            salt = Convert.FromBase64String(parts[2]);
            digest = Convert.FromBase64String(parts[3]);
        }
        catch (FormatException)
        {
            return false;
        }

        return salt.Length > 0 && digest.Length > 0;
    }
}
