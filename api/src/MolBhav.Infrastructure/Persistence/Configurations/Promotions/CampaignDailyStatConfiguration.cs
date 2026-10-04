using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Promotions;

namespace MolBhav.Infrastructure.Persistence.Configurations.Promotions;

internal sealed class CampaignDailyStatConfiguration : IEntityTypeConfiguration<CampaignDailyStat>
{
    public const string TableName = "campaign_daily_stats";

    public void Configure(EntityTypeBuilder<CampaignDailyStat> builder)
    {
        builder.ToTable(TableName, Schemas.Promotions, t =>
        {
            t.HasCheckConstraint("ck_campaign_daily_stats_counts", "impressions >= 0 AND clicks >= 0");
        });

        // One row per campaign per IST day; the PK is also the upsert's conflict target and covers the FK.
        builder.HasKey(s => new { s.CampaignId, s.Day });
        builder.Property(s => s.Impressions).IsRequired();
        builder.Property(s => s.Clicks).IsRequired();

        builder.HasOne<Campaign>().WithMany().HasForeignKey(s => s.CampaignId).OnDelete(DeleteBehavior.Cascade).IsRequired();
    }
}
