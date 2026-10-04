using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Promotions;

namespace MolBhav.Infrastructure.Persistence.Configurations.Promotions;

internal sealed class CampaignConfiguration : IEntityTypeConfiguration<Campaign>
{
    public const string TableName = "campaigns";

    public void Configure(EntityTypeBuilder<Campaign> builder)
    {
        builder.ToTable(TableName, Schemas.Promotions, t =>
        {
            t.HasCheckConstraint("ck_campaigns_schedule", "ends_at_utc > starts_at_utc");
            t.HasCheckConstraint("ck_campaigns_priority", $"priority BETWEEN 0 AND {Campaign.MaxPriority}");
            t.HasCheckConstraint("ck_campaigns_daily_cap", "daily_impression_cap IS NULL OR daily_impression_cap >= 1");
        });

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(c => c.Name).IsRequired().HasMaxLength(Campaign.NameMaxLength);
        builder.Property(c => c.Placement).IsRequired();
        builder.Property(c => c.Status).IsRequired();
        builder.Property(c => c.StartsAtUtc).IsRequired();
        builder.Property(c => c.EndsAtUtc).IsRequired();
        builder.Property(c => c.Priority).IsRequired();
        builder.Property(c => c.DailyImpressionCap);
        builder.Property(c => c.Title).IsRequired().HasMaxLength(CampaignCreative.TitleMaxLength);
        builder.Property(c => c.Body).IsRequired().HasMaxLength(CampaignCreative.BodyMaxLength);
        builder.Property(c => c.CtaLabel).IsRequired().HasMaxLength(CampaignCreative.CtaLabelMaxLength);
        builder.Property(c => c.CtaUrl).IsRequired().HasMaxLength(CampaignCreative.UrlMaxLength);
        builder.Property(c => c.ImageUrl).HasMaxLength(CampaignCreative.UrlMaxLength);

        // Restrict: a sponsor's history must not vanish because its advertiser record was deleted.
        builder.HasOne<Advertiser>().WithMany().HasForeignKey(c => c.AdvertiserId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasIndex(c => c.AdvertiserId);

        // Serving asks "active campaigns for this placement still running" on every slot render; only Active rows
        // are indexed, so drafts and the ended archive never slow it down.
        builder.HasIndex(c => new { c.Placement, c.EndsAtUtc })
            .HasDatabaseName("ix_campaigns_active_placement_ends_at_utc")
            .HasFilter("status = 'Active'");

        builder.HasMany(c => c.Targets)
            .WithOne()
            .HasForeignKey(CampaignTargetConfiguration.CampaignIdProperty)
            .OnDelete(DeleteBehavior.Cascade)
            .IsRequired();
        builder.Navigation(c => c.Targets).HasField("_targets").UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}
