using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Catalog;

/// <summary>
/// A commodity or material (BRD §11/§12): onion, tur, TMT steel, OPC 53 cement, river sand. Belongs to one
/// <see cref="SubCategory"/> (its category is derived through it) and has a default trading unit — the unit prices are
/// normalised to for display and comparison (onion: quintal; TMT: tonne; cement: 50 kg bag).
/// Deactivated, never deleted: price history references it.
/// </summary>
public sealed class Product : AggregateRoot<Guid>, IAuditableEntity
{
    public const int ImageKeyMaxLength = 200;

    private readonly List<CatalogTranslation> _translations = [];
    private readonly List<ProductVariant> _variants = [];

    private Product(Guid id, CatalogCode code, Guid subCategoryId, Guid defaultUnitId, int displayOrder, string? imageKey)
        : base(id)
    {
        Code = code;
        SubCategoryId = subCategoryId;
        DefaultUnitId = defaultUnitId;
        DisplayOrder = displayOrder;
        ImageKey = imageKey;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Product()
    {
        Code = null!;
    }

    /// <summary>Globally unique — ingestion adapters map source commodity names onto it.</summary>
    public CatalogCode Code { get; private set; }

    public Guid SubCategoryId { get; private set; }

    public Guid DefaultUnitId { get; private set; }

    public int DisplayOrder { get; private set; }

    /// <summary>Object-storage key or relative path of the product image; resolved to a URL by the client/CDN.</summary>
    public string? ImageKey { get; private set; }

    public bool IsActive { get; private set; }

    public IReadOnlyCollection<CatalogTranslation> Translations => _translations.AsReadOnly();

    public IReadOnlyCollection<ProductVariant> Variants => _variants.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>
    /// The caller (application layer) guarantees <paramref name="subCategoryId"/> and <paramref name="defaultUnitId"/>
    /// exist — they belong to other aggregates; the database FKs are the backstop.
    /// </summary>
    public static Result<Product> Create(
        CatalogCode code,
        Guid subCategoryId,
        Guid defaultUnitId,
        int displayOrder,
        string? imageKey,
        IReadOnlyCollection<CatalogTranslation> translations)
    {
        ArgumentNullException.ThrowIfNull(code);

        var check = ValidateCommon(subCategoryId, defaultUnitId, displayOrder, imageKey, translations);
        if (check.IsFailure)
        {
            return Result.Failure<Product>(check.Error);
        }

        var product = new Product(Guid.CreateVersion7(), code, subCategoryId, defaultUnitId, displayOrder, NormaliseImageKey(imageKey));
        product._translations.AddRange(translations);
        return product;
    }

    public Result Update(
        Guid subCategoryId,
        Guid defaultUnitId,
        int displayOrder,
        bool isActive,
        string? imageKey,
        IReadOnlyCollection<CatalogTranslation> translations)
    {
        var check = ValidateCommon(subCategoryId, defaultUnitId, displayOrder, imageKey, translations);
        if (check.IsFailure)
        {
            return check;
        }

        SubCategoryId = subCategoryId;
        DefaultUnitId = defaultUnitId;
        DisplayOrder = displayOrder;
        IsActive = isActive;
        ImageKey = NormaliseImageKey(imageKey);
        CatalogTranslations.Sync(_translations, translations);
        return Result.Success();
    }

    public Result<ProductVariant> AddVariant(CatalogCode code, int displayOrder, IReadOnlyCollection<CatalogTranslation> translations)
    {
        ArgumentNullException.ThrowIfNull(code);

        if (_variants.Any(v => v.Code == code))
        {
            return Error.Conflict("ProductVariant.CodeTaken", $"Variant '{code.Value}' already exists for '{Code.Value}'.");
        }

        var check = CatalogRules.ValidateItem(displayOrder, translations);
        if (check.IsFailure)
        {
            return Result.Failure<ProductVariant>(check.Error);
        }

        var variant = ProductVariant.Create(Id, code, displayOrder, translations);
        _variants.Add(variant);
        return variant;
    }

    public Result UpdateVariant(Guid variantId, int displayOrder, bool isActive, IReadOnlyCollection<CatalogTranslation> translations)
    {
        var variant = _variants.Find(v => v.Id == variantId);
        if (variant is null)
        {
            return Error.NotFound("ProductVariant.NotFound", "Variant not found for this product.");
        }

        var check = CatalogRules.ValidateItem(displayOrder, translations);
        if (check.IsFailure)
        {
            return check;
        }

        variant.Update(displayOrder, isActive, translations);
        return Result.Success();
    }

    private static Result ValidateCommon(
        Guid subCategoryId,
        Guid defaultUnitId,
        int displayOrder,
        string? imageKey,
        IReadOnlyCollection<CatalogTranslation> translations)
    {
        if (subCategoryId == Guid.Empty)
        {
            return Error.Validation("Product.SubCategoryRequired", "Sub-category is required.");
        }

        if (defaultUnitId == Guid.Empty)
        {
            return Error.Validation("Product.DefaultUnitRequired", "Default unit is required.");
        }

        if (NormaliseImageKey(imageKey) is { Length: > ImageKeyMaxLength })
        {
            return Error.Validation("Product.ImageKeyTooLong", $"Image key cannot exceed {ImageKeyMaxLength} characters.");
        }

        return CatalogRules.ValidateItem(displayOrder, translations);
    }

    private static string? NormaliseImageKey(string? imageKey) =>
        string.IsNullOrWhiteSpace(imageKey) ? null : imageKey.Trim();
}
