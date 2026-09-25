using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Catalog;

/// <summary>
/// A variety or grade of a product: Agmarknet commodity varieties (onion: red / white), steel grades (Fe 500D),
/// cement grades. Part of the <see cref="Product"/> aggregate. Price records reference product and, optionally, variant.
/// </summary>
public sealed class ProductVariant : Entity<Guid>, IAuditableEntity
{
    private readonly List<CatalogTranslation> _translations = [];

    private ProductVariant(Guid id, Guid productId, CatalogCode code, int displayOrder)
        : base(id)
    {
        ProductId = productId;
        Code = code;
        DisplayOrder = displayOrder;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private ProductVariant()
    {
        Code = null!;
    }

    public Guid ProductId { get; private set; }

    /// <summary>Unique within its product.</summary>
    public CatalogCode Code { get; private set; }

    public int DisplayOrder { get; private set; }

    public bool IsActive { get; private set; }

    public IReadOnlyCollection<CatalogTranslation> Translations => _translations.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    internal static ProductVariant Create(Guid productId, CatalogCode code, int displayOrder, IReadOnlyCollection<CatalogTranslation> translations)
    {
        var variant = new ProductVariant(Guid.CreateVersion7(), productId, code, displayOrder);
        variant._translations.AddRange(translations);
        return variant;
    }

    internal void Update(int displayOrder, bool isActive, IReadOnlyCollection<CatalogTranslation> translations)
    {
        DisplayOrder = displayOrder;
        IsActive = isActive;
        CatalogTranslations.Sync(_translations, translations);
    }
}
