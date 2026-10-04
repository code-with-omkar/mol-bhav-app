using System.Security.Cryptography;
using System.Text;
using MolBhav.Infrastructure.Monetization;

namespace MolBhav.UnitTests.Monetization;

public sealed class AdMobRewardedCallbackVerifierTests : IDisposable
{
    private const long KeyId = 3335741209;
    private const string Content =
        "ad_network=5450213213286189855&ad_unit=1234567890&custom_data=0192f0c4-3b1e-7a2b-9c3d-4e5f60718293"
        + "&reward_amount=1&reward_item=unlock&timestamp=1791040000000&transaction_id=abc123&user_id=0192f0c4-0000-7000-8000-000000000001";

    private readonly ECDsa _key = ECDsa.Create(ECCurve.NamedCurves.nistP256);
    private readonly FakeKeySource _keys = new();
    private readonly AdMobRewardedCallbackVerifier _verifier;

    public AdMobRewardedCallbackVerifierTests()
    {
        _keys.Pems[KeyId] = _key.ExportSubjectPublicKeyInfoPem();
        _verifier = new AdMobRewardedCallbackVerifier(_keys);
    }

    public void Dispose() => _key.Dispose();

    private string Sign(string content)
    {
        var signature = _key.SignData(Encoding.UTF8.GetBytes(content), HashAlgorithmName.SHA256, DSASignatureFormat.Rfc3279DerSequence);
        var webSafe = Convert.ToBase64String(signature).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return $"{content}&signature={webSafe}&key_id={KeyId}";
    }

    [Fact]
    public async Task Verify_ValidSignature_ReturnsCallback()
    {
        var callback = await _verifier.VerifyAsync(Sign(Content));

        Assert.NotNull(callback);
        Assert.Equal("abc123", callback.TransactionId);
        Assert.Equal("0192f0c4-3b1e-7a2b-9c3d-4e5f60718293", callback.CustomData);
        Assert.Equal("0192f0c4-0000-7000-8000-000000000001", callback.UserId);
        Assert.Equal(DateTimeOffset.FromUnixTimeMilliseconds(1791040000000), callback.Timestamp);
    }

    [Fact]
    public async Task Verify_LeadingQuestionMark_IsIgnored()
    {
        Assert.NotNull(await _verifier.VerifyAsync("?" + Sign(Content)));
    }

    [Fact]
    public async Task Verify_TamperedContent_ReturnsNull()
    {
        var tampered = Sign(Content).Replace("reward_amount=1", "reward_amount=9", StringComparison.Ordinal);

        Assert.Null(await _verifier.VerifyAsync(tampered));
    }

    [Fact]
    public async Task Verify_UnknownKey_ReturnsNull()
    {
        var query = Sign(Content).Replace($"key_id={KeyId}", "key_id=42", StringComparison.Ordinal);

        Assert.Null(await _verifier.VerifyAsync(query));
    }

    [Fact]
    public async Task Verify_SignedByAnotherKey_ReturnsNull()
    {
        using var other = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        _keys.Pems[KeyId] = other.ExportSubjectPublicKeyInfoPem();

        Assert.Null(await _verifier.VerifyAsync(Sign(Content)));
    }

    [Theory]
    [InlineData("")]
    [InlineData("transaction_id=abc123")]
    [InlineData("transaction_id=abc123&signature=!!notbase64!!&key_id=3335741209")]
    public async Task Verify_MalformedQuery_ReturnsNull(string query)
    {
        Assert.Null(await _verifier.VerifyAsync(query));
    }

    /// <summary>The key source is internal, which NSubstitute cannot proxy; a dictionary does the job.</summary>
    private sealed class FakeKeySource : IAdMobVerifierKeySource
    {
        public Dictionary<long, string> Pems { get; } = [];

        public Task<string?> GetPemAsync(long keyId, CancellationToken cancellationToken = default) =>
            Task.FromResult(Pems.TryGetValue(keyId, out var pem) ? pem : null);
    }
}
