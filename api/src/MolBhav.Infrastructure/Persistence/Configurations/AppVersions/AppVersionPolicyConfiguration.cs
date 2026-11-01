using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.AppVersions;

namespace MolBhav.Infrastructure.Persistence.Configurations.AppVersions;

internal sealed class AppVersionPolicyConfiguration : IEntityTypeConfiguration<AppVersionPolicy>
{
    public const string TableName = "app_version_policies";

    public void Configure(EntityTypeBuilder<AppVersionPolicy> builder)
    {
        builder.ToTable(TableName, Schemas.Platform);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(p => p.MinimumVersion).HasMaxLength(AppVersionPolicy.VersionMaxLength);
        builder.Property(p => p.UpdateUrl).HasMaxLength(AppVersionPolicy.UrlMaxLength);
    }
}
