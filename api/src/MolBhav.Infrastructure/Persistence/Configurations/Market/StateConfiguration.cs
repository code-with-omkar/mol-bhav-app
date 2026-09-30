using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Market;

namespace MolBhav.Infrastructure.Persistence.Configurations.Market;

internal sealed class StateConfiguration : IEntityTypeConfiguration<State>
{
    public const string TableName = "states";

    public void Configure(EntityTypeBuilder<State> builder)
    {
        builder.ToTable(TableName, Schemas.Market);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(s => s.Name).HasMaxLength(MarketRules.StateNameMaxLength).IsRequired();
        builder.HasIndex(s => s.Name).IsUnique();

        builder.Property(s => s.Code).HasMaxLength(MarketRules.StateCodeMaxLength).IsRequired();
        builder.HasIndex(s => s.Code).IsUnique();

        builder.Property(s => s.IsActive).IsRequired();

        builder.HasMany(s => s.Districts)
            .WithOne()
            .HasForeignKey(d => d.StateId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired();
        builder.Navigation(s => s.Districts).HasField("_districts").UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}
