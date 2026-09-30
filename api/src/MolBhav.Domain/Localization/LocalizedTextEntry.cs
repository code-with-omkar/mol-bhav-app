using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Localization;

/// <summary>
/// One data-driven piece of terminology (BRD §8/§18 "LocalizedTexts"): a key plus its text in every enabled
/// language. Backs terminology, alert titles, WhatsApp/report text and other cross-module strings that must be
/// editable without a code change. The key is immutable once created — other modules reference it by string, not
/// by id — so nothing is ever deleted, only its translations are edited.
/// </summary>
public sealed class LocalizedTextEntry : AggregateRoot<Guid>, IAuditableEntity
{
    public const int DescriptionMaxLength = 200;

    private readonly List<LocalizedTextValue> _translations = [];

    private LocalizedTextEntry(Guid id, LocalizationKey key, string? description)
        : base(id)
    {
        Key = key;
        Description = description;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private LocalizedTextEntry()
    {
        Key = null!;
    }

    /// <summary>Immutable; looked up by other modules (e.g. <c>alerts.price_drop.title</c>).</summary>
    public LocalizationKey Key { get; private set; }

    /// <summary>Admin-facing note on where/how this key is used (not shown to end users).</summary>
    public string? Description { get; private set; }

    public IReadOnlyCollection<LocalizedTextValue> Translations => _translations.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<LocalizedTextEntry> Create(LocalizationKey key, string? description, IReadOnlyCollection<LocalizedTextValue> translations)
    {
        ArgumentNullException.ThrowIfNull(key);

        var check = ValidateCommon(description, translations);
        if (check.IsFailure)
        {
            return Result.Failure<LocalizedTextEntry>(check.Error);
        }

        var entry = new LocalizedTextEntry(Guid.CreateVersion7(), key, NormaliseDescription(description));
        entry._translations.AddRange(translations);
        return entry;
    }

    public Result Update(string? description, IReadOnlyCollection<LocalizedTextValue> translations)
    {
        var check = ValidateCommon(description, translations);
        if (check.IsFailure)
        {
            return check;
        }

        Description = NormaliseDescription(description);
        LocalizedTextValues.Sync(_translations, translations);
        return Result.Success();
    }

    private static Result ValidateCommon(string? description, IReadOnlyCollection<LocalizedTextValue> translations)
    {
        if (NormaliseDescription(description) is { Length: > DescriptionMaxLength })
        {
            return Error.Validation("LocalizedTextEntry.DescriptionTooLong", $"Description cannot exceed {DescriptionMaxLength} characters.");
        }

        return LocalizedTextValues.Validate(translations);
    }

    private static string? NormaliseDescription(string? description) =>
        string.IsNullOrWhiteSpace(description) ? null : description.Trim();
}
