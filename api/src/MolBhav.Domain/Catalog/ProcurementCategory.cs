using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Domain.Catalog;

/// <summary>
/// A procurement category (BRD §6): Agriculture, Construction, and future ones added as data, not code.
/// Categories are deactivated, never deleted — price history and user selections keep referring to them.
/// </summary>
public sealed class ProcurementCategory : AggregateRoot<Guid>, IAuditableEntity
{
    public const int IconKeyMaxLength = 64;

    private readonly List<CatalogTranslation> _translations = [];
    private readonly List<SubCategory> _subCategories = [];

    private ProcurementCategory(Guid id, ProcurementCategoryCode code, string? iconKey, int displayOrder)
        : base(id)
    {
        Code = code;
        IconKey = iconKey;
        DisplayOrder = displayOrder;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private ProcurementCategory()
    {
        Code = null!;
    }

    /// <summary>Globally unique; referenced by other modules (user categories, watchlists, alerts).</summary>
    public ProcurementCategoryCode Code { get; private set; }

    /// <summary>Key of the icon bundled in the mobile app (e.g. <c>agriculture</c>); the app maps unknown keys to a generic icon.</summary>
    public string? IconKey { get; private set; }

    public int DisplayOrder { get; private set; }

    public bool IsActive { get; private set; }

    public IReadOnlyCollection<CatalogTranslation> Translations => _translations.AsReadOnly();

    public IReadOnlyCollection<SubCategory> SubCategories => _subCategories.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<ProcurementCategory> Create(
        ProcurementCategoryCode code,
        string? iconKey,
        int displayOrder,
        IReadOnlyCollection<CatalogTranslation> translations)
    {
        ArgumentNullException.ThrowIfNull(code);

        var check = ValidateCommon(iconKey, displayOrder, translations);
        if (check.IsFailure)
        {
            return Result.Failure<ProcurementCategory>(check.Error);
        }

        var category = new ProcurementCategory(Guid.CreateVersion7(), code, NormaliseIconKey(iconKey), displayOrder);
        category._translations.AddRange(translations);
        return category;
    }

    public Result Update(string? iconKey, int displayOrder, bool isActive, IReadOnlyCollection<CatalogTranslation> translations)
    {
        var check = ValidateCommon(iconKey, displayOrder, translations);
        if (check.IsFailure)
        {
            return check;
        }

        IconKey = NormaliseIconKey(iconKey);
        DisplayOrder = displayOrder;
        IsActive = isActive;
        CatalogTranslations.Sync(_translations, translations);
        return Result.Success();
    }

    public Result<SubCategory> AddSubCategory(CatalogCode code, int displayOrder, IReadOnlyCollection<CatalogTranslation> translations)
    {
        ArgumentNullException.ThrowIfNull(code);

        if (_subCategories.Any(s => s.Code == code))
        {
            return Error.Conflict("SubCategory.CodeTaken", $"Sub-category '{code.Value}' already exists in '{Code.Value}'.");
        }

        var check = CatalogRules.ValidateItem(displayOrder, translations);
        if (check.IsFailure)
        {
            return Result.Failure<SubCategory>(check.Error);
        }

        var subCategory = SubCategory.Create(Id, code, displayOrder, translations);
        _subCategories.Add(subCategory);
        return subCategory;
    }

    public Result UpdateSubCategory(Guid subCategoryId, int displayOrder, bool isActive, IReadOnlyCollection<CatalogTranslation> translations)
    {
        var subCategory = _subCategories.Find(s => s.Id == subCategoryId);
        if (subCategory is null)
        {
            return Error.NotFound("SubCategory.NotFound", "Sub-category not found in this category.");
        }

        var check = CatalogRules.ValidateItem(displayOrder, translations);
        if (check.IsFailure)
        {
            return check;
        }

        subCategory.Update(displayOrder, isActive, translations);
        return Result.Success();
    }

    private static Result ValidateCommon(string? iconKey, int displayOrder, IReadOnlyCollection<CatalogTranslation> translations)
    {
        if (NormaliseIconKey(iconKey) is { Length: > IconKeyMaxLength })
        {
            return Error.Validation("ProcurementCategory.IconKeyTooLong", $"Icon key cannot exceed {IconKeyMaxLength} characters.");
        }

        return CatalogRules.ValidateItem(displayOrder, translations);
    }

    private static string? NormaliseIconKey(string? iconKey) =>
        string.IsNullOrWhiteSpace(iconKey) ? null : iconKey.Trim().ToLowerInvariant();
}
