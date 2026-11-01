using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.AppNotices;

namespace MolBhav.Infrastructure.Persistence.Configurations.AppNotices;

internal sealed class AppNoticeConfiguration : IEntityTypeConfiguration<AppNotice>
{
    public const string TableName = "app_notices";

    public void Configure(EntityTypeBuilder<AppNotice> builder)
    {
        builder.ToTable(TableName, Schemas.Platform);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(n => n.IsActive).IsRequired();
        builder.Property(n => n.Severity).IsRequired();
        builder.Property(n => n.Message).IsRequired().HasMaxLength(AppNotice.MessageMaxLength);
    }
}
