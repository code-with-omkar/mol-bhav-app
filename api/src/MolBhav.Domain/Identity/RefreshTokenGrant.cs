using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Identity;

/// <summary>
/// One issued refresh token in a rotation chain (BRD §18 stateless JWT auth; OWASP ASVS 3.3 refresh rotation).
/// Only the SHA-256 hash is stored — never the plaintext token. Named distinctly from
/// <c>Application.Abstractions.Authentication.RefreshToken</c> (the plaintext DTO returned to the client once).
/// </summary>
public sealed class RefreshTokenGrant : AggregateRoot<Guid>, IAuditableEntity
{
    /// <summary>
    /// A token presented again within this window after being rotated is treated as a concurrent-refresh race, not theft.
    /// Short enough that a stolen token replayed later still trips reuse detection.
    /// </summary>
    public static readonly TimeSpan RotationGracePeriod = TimeSpan.FromSeconds(30);

    private RefreshTokenGrant(Guid id, Guid userId, string tokenHash, DateTimeOffset expiresAtUtc, Guid familyId)
        : base(id)
    {
        UserId = userId;
        TokenHash = tokenHash;
        ExpiresAtUtc = expiresAtUtc;
        FamilyId = familyId;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private RefreshTokenGrant()
    {
        TokenHash = string.Empty;
    }

    public Guid UserId { get; private set; }

    public string TokenHash { get; private set; }

    public DateTimeOffset ExpiresAtUtc { get; private set; }

    public DateTimeOffset? RevokedAtUtc { get; private set; }

    /// <summary>The token that replaced this one on rotation (null if revoked without rotation, e.g. logout or reuse detection).</summary>
    public Guid? ReplacedByTokenId { get; private set; }

    /// <summary>Id of the very first grant in this rotation chain — lets reuse detection revoke the whole family in one query.</summary>
    public Guid FamilyId { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>Issues the first grant of a new login — the root of its own rotation family.</summary>
    public static RefreshTokenGrant IssueInitial(Guid userId, string tokenHash, DateTimeOffset expiresAtUtc)
    {
        var id = Guid.CreateVersion7();
        return new RefreshTokenGrant(id, userId, tokenHash, expiresAtUtc, familyId: id);
    }

    /// <summary>Issues the next grant in <paramref name="parent"/>'s rotation family.</summary>
    public static RefreshTokenGrant Rotate(RefreshTokenGrant parent, string tokenHash, DateTimeOffset expiresAtUtc)
    {
        ArgumentNullException.ThrowIfNull(parent);
        return new RefreshTokenGrant(Guid.CreateVersion7(), parent.UserId, tokenHash, expiresAtUtc, parent.FamilyId);
    }

    public bool IsActive(DateTimeOffset nowUtc) => RevokedAtUtc is null && nowUtc < ExpiresAtUtc;

    /// <summary>True when this grant was rotated (not logged out / swept) within <see cref="RotationGracePeriod"/>.</summary>
    public bool WasJustRotated(DateTimeOffset nowUtc) =>
        ReplacedByTokenId is not null
        && RevokedAtUtc is { } revokedAt
        && nowUtc - revokedAt <= RotationGracePeriod;

    /// <summary>Idempotent: revoking an already-revoked grant is a no-op (repeated logout, family sweep).</summary>
    public void Revoke(DateTimeOffset nowUtc, Guid? replacedByTokenId = null)
    {
        if (RevokedAtUtc is not null)
        {
            return;
        }

        RevokedAtUtc = nowUtc;
        ReplacedByTokenId = replacedByTokenId;
    }
}
