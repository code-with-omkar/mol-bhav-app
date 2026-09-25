using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;

namespace MolBhav.Infrastructure.Persistence.Configurations.Identity;

internal sealed class RefreshTokenGrantConfiguration : IEntityTypeConfiguration<RefreshTokenGrant>
{
    public const string TableName = "refresh_tokens";

    /// <summary>Hex-encoded SHA-256 (64 chars) — see <c>JwtTokenService.HashRefreshToken</c>.</summary>
    private const int TokenHashLength = 64;

    public void Configure(EntityTypeBuilder<RefreshTokenGrant> builder)
    {
        builder.ToTable(TableName, Schemas.Identity);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(t => t.TokenHash)
            .HasMaxLength(TokenHashLength)
            .IsFixedLength()
            .IsRequired();

        builder.Property(t => t.ExpiresAtUtc).IsRequired();
        builder.Property(t => t.RevokedAtUtc);
        builder.Property(t => t.ReplacedByTokenId);
        builder.Property(t => t.FamilyId).IsRequired();

        // Tokens die with their user. Cascade is safe: users are soft-deleted, so this only fires on a
        // deliberate hard delete (e.g. a DPDP erasure request), which must take the tokens with it.
        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade)
            .IsRequired();

        // Self-reference for the rotation chain; SET NULL keeps the chain walkable if a grant is purged.
        builder.HasOne<RefreshTokenGrant>()
            .WithMany()
            .HasForeignKey(t => t.ReplacedByTokenId)
            .OnDelete(DeleteBehavior.SetNull);

        // Every refresh/logout looks a token up by its hash; unique also guards against a (theoretical) collision.
        builder.HasIndex(t => t.TokenHash).IsUnique();

        // Reuse detection revokes the still-active members of one family.
        builder.HasIndex(t => t.FamilyId)
            .HasFilter("revoked_at_utc IS NULL");

        // FK index (cascade deletes, "sign out everywhere" by user).
        builder.HasIndex(t => t.UserId);
    }
}
