using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Watchlist;

namespace MolBhav.Infrastructure.Persistence.Configurations.Watchlist;

internal sealed class WatchlistItemConfiguration : IEntityTypeConfiguration<WatchlistItem>
{
    public const string TableName = "watchlist_items";

    public void Configure(EntityTypeBuilder<WatchlistItem> builder)
    {
        builder.ToTable(TableName, Schemas.Watchlist);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        // No FK to variant here (nullable + would need a partial unique index workaround); the app layer validates
        // the variant belongs to the product on add, same as RecordPrice does for price records.
        builder.HasOne<User>().WithMany().HasForeignKey(w => w.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();
        builder.HasOne<Product>().WithMany().HasForeignKey(w => w.ProductId).OnDelete(DeleteBehavior.Restrict).IsRequired();

        // "Is this already watched?" pre-check + the user's watchlist listing.
        builder.HasIndex(w => new { w.UserId, w.ProductId, w.VariantId });
    }
}
