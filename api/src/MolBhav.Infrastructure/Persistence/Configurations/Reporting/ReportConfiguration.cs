using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Reporting;

namespace MolBhav.Infrastructure.Persistence.Configurations.Reporting;

internal sealed class ReportConfiguration : IEntityTypeConfiguration<Report>
{
    public const string TableName = "reports";

    public void Configure(EntityTypeBuilder<Report> builder)
    {
        builder.ToTable(TableName, Schemas.Reporting);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(r => r.ReportType).IsRequired();
        builder.Property(r => r.Format).IsRequired();
        builder.Property(r => r.ParametersJson).HasColumnType("jsonb").IsRequired();
        builder.Property(r => r.Status).IsRequired();
        builder.Property(r => r.DownloadUrl).HasMaxLength(500);
        builder.Property(r => r.FailureReason).HasMaxLength(Report.FailureReasonMaxLength);
        builder.Property(r => r.RequestedAtUtc).IsRequired();
        builder.Property(r => r.LastDownloadedAtUtc);

        builder.HasOne<User>().WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // The user's report list, newest first; admin monitoring filters by status/type/user.
        builder.HasIndex(r => new { r.UserId, r.RequestedAtUtc });
        builder.HasIndex(r => r.Status);
    }
}
