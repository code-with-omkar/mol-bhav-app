using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using MolBhav.Application.Abstractions.Authentication;

namespace MolBhav.Infrastructure.Authentication;

internal sealed class OtpCodeGenerator : IOtpCodeGenerator
{
    public const int CodeLength = 6;

    private static readonly int ExclusiveUpperBound = (int)Math.Pow(10, CodeLength);

    /// <summary><see cref="RandomNumberGenerator.GetInt32(int)"/> is CSPRNG-backed and rejection-sampled (no modulo bias).</summary>
    public string GenerateCode() =>
        RandomNumberGenerator.GetInt32(ExclusiveUpperBound).ToString($"D{CodeLength}", CultureInfo.InvariantCulture);

    /// <summary>
    /// SHA-256 over "phone:code". A 6-digit code has only 10^6 values, so this hash alone would not resist an offline
    /// brute force by someone holding the database — the real protection is online: 5-minute lifetime, 5 attempts per
    /// challenge (<c>OtpChallenge</c>) and the per-IP OTP rate limit. Hashing keeps live codes out of backups, logs and
    /// casual DB reads; the phone salt stops one precomputed table covering every user.
    /// </summary>
    public string Hash(string phoneNumber, string code)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(phoneNumber);
        ArgumentException.ThrowIfNullOrWhiteSpace(code);

        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes($"{phoneNumber}:{code}")));
    }
}
