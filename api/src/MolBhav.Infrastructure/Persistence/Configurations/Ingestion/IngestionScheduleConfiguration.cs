using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;

namespace MolBhav.Infrastructure.Persistence.Configurations.Ingestion;

internal sealed class IngestionScheduleConfiguration : IEntityTypeConfiguration<IngestionSchedule>
{
    public const string TableName = "ingestion_schedules";

    private const int EnumMaxLength = 20;

    public void Configure(EntityTypeBuilder<IngestionSchedule> builder)
    {
        builder.ToTable(TableName, Schemas.Ingestion, t =>
        {
            // The domain enforces these too; the database is the last line against a bad write path.
            t.HasCheckConstraint(
                "ck_ingestion_schedules_day_of_week",
                "(frequency = 'Weekly' AND day_of_week IS NOT NULL) OR (frequency <> 'Weekly' AND day_of_week IS NULL)");
            t.HasCheckConstraint(
                "ck_ingestion_schedules_interval_hours",
                "(frequency = 'EveryNHours' AND interval_hours IN (1, 2, 3, 4, 6, 8, 12)) OR (frequency <> 'EveryNHours' AND interval_hours IS NULL)");
            t.HasCheckConstraint(
                "ck_ingestion_schedules_next_run",
                "(is_enabled AND next_run_at_utc IS NOT NULL) OR (NOT is_enabled AND next_run_at_utc IS NULL)");
        });

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(s => s.IsEnabled).IsRequired();
        builder.Property(s => s.Frequency).HasConversion<string>().HasMaxLength(EnumMaxLength).IsRequired();
        builder.Property(s => s.TimeOfDay).IsRequired();
        builder.Property(s => s.DayOfWeek).HasConversion<string>().HasMaxLength(EnumMaxLength);
        builder.Property(s => s.IntervalHours);
        builder.Property(s => s.NextRunAtUtc);
        builder.Property(s => s.LastRunAtUtc);

        // Restrict, not cascade: sources are deactivated, never deleted.
        builder.HasOne<PriceSource>().WithMany().HasForeignKey(s => s.PriceSourceId).OnDelete(DeleteBehavior.Restrict).IsRequired();

        // One schedule per source (also covers the FK).
        builder.HasIndex(s => s.PriceSourceId).IsUnique();

        // The scheduler's per-minute "due now" query touches only enabled rows.
        builder.HasIndex(s => s.NextRunAtUtc).HasFilter("is_enabled");
    }
}
