namespace MolBhav.Application.Abstractions.Authentication;

/// <summary>Generates and hashes one-time verification codes. The plaintext code is never persisted (see <c>OtpChallenge</c>).</summary>
public interface IOtpCodeGenerator
{
    /// <summary>A uniformly random numeric code (fixed length — see the implementation for digit count).</summary>
    string GenerateCode();

    /// <summary>Deterministic hash of <paramref name="code"/> salted with <paramref name="phoneNumber"/>, so two phones that are (improbably) issued the same code do not collide in storage.</summary>
    string Hash(string phoneNumber, string code);
}
