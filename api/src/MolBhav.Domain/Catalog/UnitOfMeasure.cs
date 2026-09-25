using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Catalog;

/// <summary>
/// A trading unit (BRD §6/§11/§12): kg, quintal, tonne, 50 kg bag, piece, cft, brass. Prices from different sources
/// arrive in different units (mandi: ₹/quintal; retail: ₹/kg; cement: ₹/bag), so every unit carries a factor to its
/// dimension's base unit and comparisons convert through it.
/// </summary>
public sealed class UnitOfMeasure : AggregateRoot<Guid>, IAuditableEntity
{
    public const int SymbolMaxLength = 16;

    /// <summary>Factor precision: 6 decimals covers gram → kg (0.001) and cft → m³ (0.028317).</summary>
    public const int FactorScale = 6;

    private readonly List<CatalogTranslation> _translations = [];

    private UnitOfMeasure(Guid id, CatalogCode code, string symbol, MeasureDimension dimension, decimal toBaseFactor)
        : base(id)
    {
        Code = code;
        Symbol = symbol;
        Dimension = dimension;
        ToBaseFactor = toBaseFactor;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private UnitOfMeasure()
    {
        Code = null!;
        Symbol = string.Empty;
    }

    public CatalogCode Code { get; private set; }

    /// <summary>Short display symbol, language-neutral: kg, q, t, bag, pc, cft.</summary>
    public string Symbol { get; private set; }

    /// <summary>Immutable: changing it would silently corrupt every price already recorded in this unit.</summary>
    public MeasureDimension Dimension { get; private set; }

    /// <summary>How many base units one of this unit is (quintal → 100 kg). Immutable for the same reason as <see cref="Dimension"/>; a correction is a new unit.</summary>
    public decimal ToBaseFactor { get; private set; }

    public bool IsActive { get; private set; }

    public IReadOnlyCollection<CatalogTranslation> Translations => _translations.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<UnitOfMeasure> Create(
        CatalogCode code,
        string? symbol,
        MeasureDimension dimension,
        decimal toBaseFactor,
        IReadOnlyCollection<CatalogTranslation> translations)
    {
        ArgumentNullException.ThrowIfNull(code);

        var symbolResult = NormaliseSymbol(symbol);
        if (symbolResult.IsFailure)
        {
            return Result.Failure<UnitOfMeasure>(symbolResult.Error);
        }

        if (!Enum.IsDefined(dimension))
        {
            return Error.Validation("UnitOfMeasure.InvalidDimension", "Unknown measure dimension.");
        }

        if (toBaseFactor <= 0m || decimal.Round(toBaseFactor, FactorScale) != toBaseFactor)
        {
            return Error.Validation(
                "UnitOfMeasure.InvalidFactor",
                $"Conversion factor must be positive with at most {FactorScale} decimal places.");
        }

        var translationCheck = CatalogTranslations.Validate(translations);
        if (translationCheck.IsFailure)
        {
            return Result.Failure<UnitOfMeasure>(translationCheck.Error);
        }

        var unit = new UnitOfMeasure(Guid.CreateVersion7(), code, symbolResult.Value, dimension, toBaseFactor);
        unit._translations.AddRange(translations);
        return unit;
    }

    public Result Update(string? symbol, bool isActive, IReadOnlyCollection<CatalogTranslation> translations)
    {
        var symbolResult = NormaliseSymbol(symbol);
        if (symbolResult.IsFailure)
        {
            return symbolResult.Error;
        }

        var translationCheck = CatalogTranslations.Validate(translations);
        if (translationCheck.IsFailure)
        {
            return translationCheck;
        }

        Symbol = symbolResult.Value;
        IsActive = isActive;
        CatalogTranslations.Sync(_translations, translations);
        return Result.Success();
    }

    /// <summary>Multiplier converting a quantity in this unit to <paramref name="target"/> (quintal → kg = 100).</summary>
    public Result<decimal> ConversionFactorTo(UnitOfMeasure target)
    {
        ArgumentNullException.ThrowIfNull(target);

        return target.Dimension == Dimension
            ? ToBaseFactor / target.ToBaseFactor
            : Error.BusinessRule(
                "UnitOfMeasure.IncompatibleDimensions",
                $"Cannot convert {Code.Value} ({Dimension}) to {target.Code.Value} ({target.Dimension}).");
    }

    private static Result<string> NormaliseSymbol(string? symbol)
    {
        if (string.IsNullOrWhiteSpace(symbol))
        {
            return Error.Validation("UnitOfMeasure.SymbolRequired", "Symbol is required.");
        }

        var trimmed = symbol.Trim();
        return trimmed.Length <= SymbolMaxLength
            ? trimmed
            : Error.Validation("UnitOfMeasure.SymbolTooLong", $"Symbol cannot exceed {SymbolMaxLength} characters.");
    }
}
