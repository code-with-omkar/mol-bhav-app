using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Monetization;

namespace MolBhav.Infrastructure.Persistence.Configurations.Monetization;

internal sealed class RewardedAdViewConfiguration : IEntityTypeConfiguration<RewardedAdView>
{
    public const string TableName = "rewarded_ad_views";

    public void Configure(EntityTypeBuilder<RewardedAdView> builder)
    {
        builder.ToTable(TableName, Schemas.Monetization);

        builder.ConfigureAggregateRoot();

        builder.Property(v => v.TransactionId).IsRequired().HasMaxLength(RewardedAdView.TransactionIdMaxLength);
        builder.Property(v => v.AdNetwork).IsRequired().HasMaxLength(RewardedAdView.AdNetworkMaxLength);
        builder.Property(v => v.AdUnit).IsRequired().HasMaxLength(RewardedAdView.AdUnitMaxLength);
        builder.Property(v => v.VerifiedAtUtc).IsRequired();

        builder.HasOne<User>().WithMany().HasForeignKey(v => v.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();
        builder.HasOne<AdUnlockSession>().WithMany().HasForeignKey(v => v.SessionId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // Idempotency: AdMob may deliver one view's callback more than once; the second insert must fail, not double-count.
        builder.HasIndex(v => v.TransactionId).IsUnique();

        // FK covers.
        builder.HasIndex(v => v.UserId);
        builder.HasIndex(v => v.SessionId);
    }
}
