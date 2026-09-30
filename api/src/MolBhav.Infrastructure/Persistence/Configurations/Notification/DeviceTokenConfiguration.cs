using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Notification;

namespace MolBhav.Infrastructure.Persistence.Configurations.Notification;

internal sealed class DeviceTokenConfiguration : IEntityTypeConfiguration<DeviceToken>
{
    public void Configure(EntityTypeBuilder<DeviceToken> builder)
    {
        builder.InSchema(Schemas.Notification);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(d => d.UserId).IsRequired();
        builder.Property(d => d.Token).HasMaxLength(DeviceToken.TokenMaxLength).IsRequired();
        builder.Property(d => d.Platform).IsRequired();

        builder.HasOne<User>().WithMany().HasForeignKey(d => d.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        // Unique per (user, token) — prevents duplicate registrations.
        builder.HasIndex(d => new { d.UserId, d.Token }).IsUnique();

        // Fetch all tokens for a user in one query when building a multicast.
        builder.HasIndex(d => d.UserId);
    }
}
