using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Audit;

namespace MolBhav.Infrastructure.Persistence.Configurations.Audit;

internal sealed class AuditEntryConfiguration : IEntityTypeConfiguration<AuditEntry>
{
    public const string TableName = "audit_entries";

    public void Configure(EntityTypeBuilder<AuditEntry> builder)
    {
        builder.ToTable(TableName, Schemas.Platform);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        // No foreign key to the user: the log must outlive and never block any account change, and modules do not
        // reference each other's tables.
        builder.Property(e => e.ActorUserId).IsRequired();
        builder.Property(e => e.Action).IsRequired().HasMaxLength(AuditEntry.ActionMaxLength);
        builder.Property(e => e.Target).HasMaxLength(AuditEntry.TargetMaxLength);
        builder.Property(e => e.Summary).IsRequired().HasMaxLength(AuditEntry.SummaryMaxLength);
        builder.Property(e => e.OccurredAtUtc).IsRequired();

        // The screen reads newest first, optionally one action.
        builder.HasIndex(e => e.OccurredAtUtc).IsDescending();
        builder.HasIndex(e => new { e.Action, e.OccurredAtUtc }).IsDescending(false, true);
    }
}
