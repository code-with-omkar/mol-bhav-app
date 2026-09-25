using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Catalog;

/// <summary>
/// A grouping inside a category (Agriculture → Vegetables / Grains / Pulses; Construction → Steel / Cement / …).
/// Part of the <see cref="ProcurementCategory"/> aggregate: created and changed only through it. Products reference
/// it by id — the category is then derived through it rather than stored again on the product (3NF).
/// </summary>
public sealed class SubCategory : Entity<Guid>, IAuditableEntity
{
    private readonly List<CatalogTranslation> _translations = [];

    private SubCategory(Guid id, Guid categoryId, CatalogCode code, int displayOrder)
        : base(id)
    {
        CategoryId = categoryId;
        Code = code;
        DisplayOrder = displayOrder;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private SubCategory()
    {
        Code = null!;
    }

    public Guid CategoryId { get; private set; }

    /// <summary>Unique within its category.</summary>
    public CatalogCode Code { get; private set; }

    public int DisplayOrder { get; private set; }

    public bool IsActive { get; private set; }

    public IReadOnlyCollection<CatalogTranslation> Translations => _translations.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    internal static SubCategory Create(Guid categoryId, CatalogCode code, int displayOrder, IReadOnlyCollection<CatalogTranslation> translations)
    {
        var subCategory = new SubCategory(Guid.CreateVersion7(), categoryId, code, displayOrder);
        subCategory._translations.AddRange(translations);
        return subCategory;
    }

    internal void Update(int displayOrder, bool isActive, IReadOnlyCollection<CatalogTranslation> translations)
    {
        DisplayOrder = displayOrder;
        IsActive = isActive;
        CatalogTranslations.Sync(_translations, translations);
    }
}
