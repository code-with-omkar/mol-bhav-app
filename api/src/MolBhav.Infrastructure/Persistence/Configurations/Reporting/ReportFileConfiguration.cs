using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Reporting;
using MolBhav.Infrastructure.Reporting;

namespace MolBhav.Infrastructure.Persistence.Configurations.Reporting;

internal sealed class ReportFileConfiguration : IEntityTypeConfiguration<ReportFile>
{
    public const string TableName = "report_files";

    public void Configure(EntityTypeBuilder<ReportFile> builder)
    {
        builder.ToTable(TableName, Schemas.Reporting);

        builder.HasKey(f => f.ReportId);
        builder.Property(f => f.ReportId).ValueGeneratedNever();
        builder.Property(f => f.FileName).HasMaxLength(200).IsRequired();
        builder.Property(f => f.ContentType).HasMaxLength(100).IsRequired();
        builder.Property(f => f.SizeBytes).IsRequired();
        builder.Property(f => f.Content).HasColumnType("bytea").IsRequired();
        builder.Property(f => f.CreatedAtUtc).IsRequired();

        builder.HasOne<Report>().WithOne().HasForeignKey<ReportFile>(f => f.ReportId).OnDelete(DeleteBehavior.Cascade);
    }
}
