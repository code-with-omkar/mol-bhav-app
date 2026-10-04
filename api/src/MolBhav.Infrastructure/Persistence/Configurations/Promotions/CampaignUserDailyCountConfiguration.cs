using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Promotions;

namespace MolBhav.Infrastructure.Persistence.Configurations.Promotions;

internal sealed class CampaignUserDailyCountConfiguration : IEntityTypeConfiguration<CampaignUserDailyCount>
{
    public const string TableName = "campaign_user_daily_counts";

    public void Configure(EntityTypeBuilder<CampaignUserDailyCount> builder)
    {
        builder.ToTable(TableName, Schemas.Promotions, t =>
        {
            t.HasCheckConstraint(
                "ck_campaign_user_daily_counts_counts",
                $"impressions BETWEEN 0 AND {CampaignUserDailyCount.MaxImpressions} AND clicks BETWEEN 0 AND {CampaignUserDailyCount.MaxClicks}");
        });

        // The upsert's conflict target; leads with campaign_id, so it also covers the campaign FK.
        builder.HasKey(c => new { c.CampaignId, c.UserId, c.Day });
        builder.Property(c => c.Impressions).IsRequired();
        builder.Property(c => c.Clicks).IsRequired();

        builder.HasOne<Campaign>().WithMany().HasForeignKey(c => c.CampaignId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // No FK to identity.users: modules only reference shared reference data across schemas (see Schemas), and a
        // deleted account's counts are harmless aggregates. Indexed by day for the retention purge of old rows.
        builder.HasIndex(c => c.Day);
    }
}
