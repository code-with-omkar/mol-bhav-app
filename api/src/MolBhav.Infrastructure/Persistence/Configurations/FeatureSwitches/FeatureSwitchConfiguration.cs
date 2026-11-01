using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Infrastructure.Persistence.Configurations.FeatureSwitches;

internal sealed class FeatureSwitchConfiguration : IEntityTypeConfiguration<FeatureSwitch>
{
    public const string TableName = "feature_switches";

    public void Configure(EntityTypeBuilder<FeatureSwitch> builder)
    {
        builder.ToTable(TableName, Schemas.Platform);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(f => f.Feature).IsRequired();
        builder.Property(f => f.IsEnabled).IsRequired();

        // One switch per feature.
        builder.HasIndex(f => f.Feature).IsUnique();
    }
}
