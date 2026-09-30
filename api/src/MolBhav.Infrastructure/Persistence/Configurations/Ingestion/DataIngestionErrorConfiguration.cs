using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Infrastructure.Persistence.Configurations.Ingestion;

internal sealed class DataIngestionErrorConfiguration : IEntityTypeConfiguration<DataIngestionError>
{
    public const string TableName = "ingestion_errors";

    public void Configure(EntityTypeBuilder<DataIngestionError> builder)
    {
        builder.ToTable(TableName, Schemas.Ingestion);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(e => e.RawPayload).HasColumnType("jsonb").IsRequired();
        builder.Property(e => e.ErrorMessage).HasMaxLength(DataIngestionError.ErrorMessageMaxLength).IsRequired();
        builder.Property(e => e.OccurredAtUtc).IsRequired();

        // Cascade: an error has no independent value once its job is gone (jobs are never deleted in practice, but the FK stays honest).
        builder.HasOne<DataIngestionJob>().WithMany().HasForeignKey(e => e.JobId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // Admin drill-down: a job's errors, in order.
        builder.HasIndex(e => new { e.JobId, e.OccurredAtUtc });
    }
}
