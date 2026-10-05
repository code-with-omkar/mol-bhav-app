using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;

namespace MolBhav.Infrastructure.Persistence.Configurations.Ingestion;

internal sealed class DataIngestionJobConfiguration : IEntityTypeConfiguration<DataIngestionJob>
{
    public const string TableName = "ingestion_jobs";

    public void Configure(EntityTypeBuilder<DataIngestionJob> builder)
    {
        builder.ToTable(TableName, Schemas.Ingestion);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(j => j.TriggerType).IsRequired();
        builder.Property(j => j.Status).IsRequired();
        builder.Property(j => j.RecordsFetched).IsRequired();
        builder.Property(j => j.RecordsPersisted).IsRequired();
        builder.Property(j => j.RecordsFailed).IsRequired();
        builder.Property(j => j.RecordsUnchanged).IsRequired().HasDefaultValue(0);
        builder.Property(j => j.AsOfDate);
        builder.Property(j => j.FailureReason).HasMaxLength(DataIngestionJob.FailureReasonMaxLength);
        builder.Property(j => j.StartedAtUtc).IsRequired();

        // Restrict, not cascade: the source is admin-managed reference data and is deactivated, never deleted.
        builder.HasOne<PriceSource>().WithMany().HasForeignKey(j => j.PriceSourceId).OnDelete(DeleteBehavior.Restrict).IsRequired();
        builder.HasOne<User>().WithMany().HasForeignKey(j => j.TriggeredByUserId).OnDelete(DeleteBehavior.SetNull);

        // Admin monitoring: jobs for one source, newest first; filtering by status.
        builder.HasIndex(j => new { j.PriceSourceId, j.StartedAtUtc });
        builder.HasIndex(j => j.Status);
    }
}
