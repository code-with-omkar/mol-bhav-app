using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Monetization;

namespace MolBhav.Infrastructure.Persistence.Configurations.Monetization;

internal sealed class FeatureGrantConfiguration : IEntityTypeConfiguration<FeatureGrant>
{
    public const string TableName = "feature_grants";

    public void Configure(EntityTypeBuilder<FeatureGrant> builder)
    {
        builder.ToTable(TableName, Schemas.Monetization, t =>
        {
            t.HasCheckConstraint("ck_feature_grants_quantity", "quantity >= 1");
        });

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(g => g.Feature).IsRequired();
        builder.Property(g => g.Quantity).IsRequired();
        builder.Property(g => g.Source).IsRequired();
        builder.Property(g => g.GrantedAtUtc).IsRequired();
        builder.Property(g => g.ExpiresAtUtc);
        builder.Property(g => g.ConsumedAtUtc);

        builder.HasOne<User>().WithMany().HasForeignKey(g => g.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // Every entitlement check asks "this user's grants for this feature" (capacity sums, daily caps by granted_at).
        // Leading user_id also covers the FK.
        builder.HasIndex(g => new { g.UserId, g.Feature, g.GrantedAtUtc });

        // Report unlocks waiting to be used: tiny, because consumed grants (the vast majority over time) drop out.
        builder.HasIndex(g => new { g.UserId, g.Feature })
            .HasDatabaseName("ix_feature_grants_unconsumed")
            .HasFilter("consumed_at_utc IS NULL");
    }
}
