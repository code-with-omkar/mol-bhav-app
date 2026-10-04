using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using MolBhav.Application.Abstractions.Monetization;

namespace MolBhav.Infrastructure.Monetization;

/// <summary>
/// Verifies AdMob rewarded-ad SSV callbacks: AdMob signs everything before <c>&amp;signature=</c> with ECDSA P-256 /
/// SHA-256 (DER), and <c>signature</c> then <c>key_id</c> are always the last two parameters. The signature is
/// web-safe base64. Nothing in the callback is trusted until the signature checks out.
/// </summary>
internal sealed class AdMobRewardedCallbackVerifier(IAdMobVerifierKeySource keySource) : IRewardedAdCallbackVerifier
{
    private const string SignatureMarker = "&signature=";

    public async Task<RewardedAdCallback?> VerifyAsync(string rawQueryString, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrEmpty(rawQueryString))
        {
            return null;
        }

        var query = rawQueryString.StartsWith('?') ? rawQueryString[1..] : rawQueryString;
        var signatureAt = query.IndexOf(SignatureMarker, StringComparison.Ordinal);
        if (signatureAt <= 0)
        {
            return null;
        }

        var signedContent = query[..signatureAt];
        var parameters = Parse(query);

        if (!parameters.TryGetValue("signature", out var signatureText)
            || AdMobVerifierKeySource.ParseKeyId(parameters.GetValueOrDefault("key_id")) is not { } keyId
            || !TryDecodeWebSafeBase64(signatureText, out var signature))
        {
            return null;
        }

        var pem = await keySource.GetPemAsync(keyId, cancellationToken);
        if (pem is null || !Verify(pem, Encoding.UTF8.GetBytes(signedContent), signature))
        {
            return null;
        }

        if (!parameters.TryGetValue("transaction_id", out var transactionId)
            || string.IsNullOrWhiteSpace(transactionId)
            || !long.TryParse(parameters.GetValueOrDefault("timestamp"), NumberStyles.None, CultureInfo.InvariantCulture, out var timestampMs))
        {
            return null;
        }

        return new RewardedAdCallback(
            transactionId,
            parameters.GetValueOrDefault("user_id"),
            parameters.GetValueOrDefault("custom_data"),
            parameters.GetValueOrDefault("ad_network") ?? string.Empty,
            parameters.GetValueOrDefault("ad_unit") ?? string.Empty,
            DateTimeOffset.FromUnixTimeMilliseconds(timestampMs));
    }

    private static bool Verify(string pem, byte[] content, byte[] signature)
    {
        try
        {
            using var ecdsa = ECDsa.Create();
            ecdsa.ImportFromPem(pem);
            return ecdsa.VerifyData(content, signature, HashAlgorithmName.SHA256, DSASignatureFormat.Rfc3279DerSequence);
        }
        catch (Exception ex) when (ex is CryptographicException or ArgumentException)
        {
            return false;
        }
    }

    /// <summary>Last occurrence wins; values are percent-decoded (only <c>custom_data</c> is ever encoded in practice).</summary>
    private static Dictionary<string, string> Parse(string query)
    {
        var result = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var pair in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var eq = pair.IndexOf('=', StringComparison.Ordinal);
            var name = eq < 0 ? pair : pair[..eq];
            var value = eq < 0 ? string.Empty : pair[(eq + 1)..];
            result[Uri.UnescapeDataString(name)] = Uri.UnescapeDataString(value.Replace('+', ' '));
        }

        return result;
    }

    private static bool TryDecodeWebSafeBase64(string value, out byte[] bytes)
    {
        var standard = value.Replace('-', '+').Replace('_', '/');
        standard = (standard.Length % 4) switch
        {
            2 => standard + "==",
            3 => standard + "=",
            _ => standard,
        };

        bytes = new byte[standard.Length];
        if (Convert.TryFromBase64String(standard, bytes, out var written))
        {
            bytes = bytes[..written];
            return true;
        }

        bytes = [];
        return false;
    }
}
