using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Promotions;

namespace MolBhav.Infrastructure.Persistence.Configurations.Promotions;

internal sealed class AdvertiserConfiguration : IEntityTypeConfiguration<Advertiser>
{
    public const string TableName = "advertisers";

    public void Configure(EntityTypeBuilder<Advertiser> builder)
    {
        builder.ToTable(TableName, Schemas.Promotions);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(a => a.Name).IsRequired().HasMaxLength(Advertiser.NameMaxLength);
        builder.Property(a => a.ContactName).HasMaxLength(Advertiser.ContactMaxLength);
        builder.Property(a => a.ContactPhone).HasMaxLength(Advertiser.PhoneMaxLength);
        builder.Property(a => a.Gstin).HasMaxLength(Advertiser.GstinLength);

        // The admin list is ordered by name.
        builder.HasIndex(a => a.Name);
    }
}
