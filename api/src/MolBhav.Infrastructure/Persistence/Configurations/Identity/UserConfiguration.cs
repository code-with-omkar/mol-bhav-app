using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Identity;

internal sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    // Pinned (not left to the convention): "user" is a reserved word in PostgreSQL, and the Dapper profile read
    // service references these names in SQL.
    public const string TableName = "users";
    public const string CategoriesTableName = "user_categories";
    public const string QualifiedTableName = Schemas.Identity + "." + TableName;
    public const string QualifiedCategoriesTableName = Schemas.Identity + "." + CategoriesTableName;

    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable(TableName, Schemas.Identity);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing()
            .ConfigureSoftDelete();

        builder.Property(u => u.PhoneNumber)
            .HasConversion(ValueObjectConverters.PhoneNumberConverter)
            .HasMaxLength(PhoneNumber.MaxLength)
            .IsRequired();

        builder.Property(u => u.PreferredLanguage)
            .HasConversion(ValueObjectConverters.LanguageCodeConverter)
            .HasMaxLength(LanguageCode.MaxLength)
            .IsFixedLength()
            .IsRequired();

        builder.Property(u => u.Status).IsRequired();
        builder.Property(u => u.SubscriptionTier).IsRequired();
        builder.Property(u => u.Role).IsRequired();
        builder.Property(u => u.LastLoginAtUtc);

        builder.Ignore(u => u.IsOnboarded);

        // Table-split owned type: profile columns live on identity.users (1:1, always loaded with the user).
        builder.OwnsOne(u => u.Profile, profile =>
        {
            profile.Property(p => p.BusinessType).HasColumnName("business_type").HasMaxLength(UserProfile.FieldMaxLength);
            profile.Property(p => p.State).HasColumnName("state").HasMaxLength(UserProfile.FieldMaxLength);
            profile.Property(p => p.District).HasColumnName("district").HasMaxLength(UserProfile.FieldMaxLength);
        });
        builder.Navigation(u => u.Profile).IsRequired();

        builder.OwnsMany(u => u.Categories, category =>
        {
            category.ToTable(CategoriesTableName, Schemas.Identity);
            category.WithOwner().HasForeignKey("UserId");
            category.Property<Guid>("UserId").HasColumnName("user_id");
            category.Property(c => c.CategoryCode)
                .HasConversion(ValueObjectConverters.ProcurementCategoryCodeConverter)
                .HasColumnName("category_code")
                .HasMaxLength(ProcurementCategoryCode.MaxLength)
                .IsRequired();

            // Natural composite key: a user holds each category at most once.
            category.HasKey("UserId", nameof(UserProfileCategory.CategoryCode));

            // Cross-schema FK into catalog reference data (allowed direction — see Schemas). Restrict: categories are
            // deactivated, never deleted. Referencing the code (the category's alternate key) keeps the row readable
            // without a join and matches what the API exchanges.
            category.HasOne<ProcurementCategory>()
                .WithMany()
                .HasForeignKey(c => c.CategoryCode)
                .HasPrincipalKey(c => c.Code)
                .OnDelete(DeleteBehavior.Restrict);

            // Reverse lookup ("who operates in construction?") for category-targeted alerts/notifications; also the FK index.
            category.HasIndex(c => c.CategoryCode);
        });
        builder.Navigation(u => u.Categories).HasField("_categories").UsePropertyAccessMode(PropertyAccessMode.Field);

        // One account per phone number among live (non-deleted) users — the OTP login identifier.
        // Filtered so a soft-deleted account does not block re-registration of the same number.
        builder.HasIndex(u => u.PhoneNumber)
            .IsUnique()
            .HasFilter("is_deleted = false");
    }
}
