using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Market;
using MolBhav.Domain.Promotions;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Persistence.Configurations.Promotions;

internal sealed class CampaignTargetConfiguration : IEntityTypeConfiguration<CampaignTarget>
{
    public const string TableName = "campaign_targets";

    /// <summary>Shadow FK to the owning campaign — the target carries no back-reference.</summary>
    public const string CampaignIdProperty = "CampaignId";

    public void Configure(EntityTypeBuilder<CampaignTarget> builder)
    {
        builder.ToTable(TableName, Schemas.Promotions);

        builder.HasKey(t => t.Id);
        builder.Property(t => t.Id).ValueGeneratedNever();
        builder.Property<Guid>(CampaignIdProperty).HasColumnName("campaign_id");

        // Validated against the catalog when the campaign is saved. No FK: the catalog key is mapped through the
        // ProcurementCategoryCode converter, while a target stores the normalised code as plain text.
        builder.Property(t => t.CategoryCode).IsRequired().HasMaxLength(ProcurementCategoryCode.MaxLength);

        // Cross-schema FK to reference data (allowed by Schemas): a state can't be deleted while a campaign targets it.
        builder.HasOne<State>().WithMany().HasForeignKey(t => t.StateId).OnDelete(DeleteBehavior.Restrict);

        // Serving checks "does this campaign target the user" per candidate campaign; also covers the FK.
        builder.HasIndex(CampaignIdProperty, nameof(CampaignTarget.CategoryCode));
        builder.HasIndex(t => t.StateId);
    }
}
