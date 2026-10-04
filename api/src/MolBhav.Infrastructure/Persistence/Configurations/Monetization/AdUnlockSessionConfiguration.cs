using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Monetization;

namespace MolBhav.Infrastructure.Persistence.Configurations.Monetization;

internal sealed class AdUnlockSessionConfiguration : IEntityTypeConfiguration<AdUnlockSession>
{
    public const string TableName = "ad_unlock_sessions";

    public void Configure(EntityTypeBuilder<AdUnlockSession> builder)
    {
        builder.ToTable(TableName, Schemas.Monetization, t =>
        {
            t.HasCheckConstraint("ck_ad_unlock_sessions_ads", "ads_required >= 1 AND ads_verified >= 0");
        });

        // xmin guards the Pending → Granted transition: two callbacks completing the same session cannot both grant.
        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(s => s.Feature).IsRequired();
        builder.Property(s => s.AdsRequired).IsRequired();
        builder.Property(s => s.AdsVerified).IsRequired();
        builder.Property(s => s.Status).IsRequired();
        builder.Property(s => s.ExpiresAtUtc).IsRequired();
        builder.Property(s => s.GrantedAtUtc);

        builder.HasOne<User>().WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // FK cover; sessions are only ever read by id, so no wider index is justified.
        builder.HasIndex(s => s.UserId);
    }
}
