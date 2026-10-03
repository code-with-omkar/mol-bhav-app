using System.Security.Cryptography;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Infrastructure.Authentication;

namespace MolBhav.UnitTests.Identity;

public sealed class Pbkdf2PasswordHasherTests
{
    private readonly Pbkdf2PasswordHasher _hasher = new();

    [Fact]
    public void Verify_CorrectPassword_Succeeds()
    {
        var hash = _hasher.Hash("kanda2026");

        Assert.StartsWith("pbkdf2-sha256$600000$", hash, StringComparison.Ordinal);
        Assert.Equal(PasswordVerificationResult.Success, _hasher.Verify(hash, "kanda2026"));
    }

    [Fact]
    public void Verify_WrongPassword_Fails()
    {
        var hash = _hasher.Hash("kanda2026");

        Assert.Equal(PasswordVerificationResult.Failed, _hasher.Verify(hash, "kanda2027"));
    }

    [Fact]
    public void Hash_SamePasswordTwice_UsesDifferentSalts()
    {
        Assert.NotEqual(_hasher.Hash("kanda2026"), _hasher.Hash("kanda2026"));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("not-a-hash")]
    [InlineData("md5$1$AAAA$AAAA")]
    public void Verify_MissingOrForeignHash_Fails(string? stored)
    {
        Assert.Equal(PasswordVerificationResult.Failed, _hasher.Verify(stored, "kanda2026"));
    }

    [Fact]
    public void Verify_LowerWorkFactor_RequestsRehash()
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        var digest = Rfc2898DeriveBytes.Pbkdf2("kanda2026", salt, 1_000, HashAlgorithmName.SHA256, 32);
        var legacy = $"pbkdf2-sha256$1000${Convert.ToBase64String(salt)}${Convert.ToBase64String(digest)}";

        Assert.Equal(PasswordVerificationResult.SuccessRehashNeeded, _hasher.Verify(legacy, "kanda2026"));
    }
}
