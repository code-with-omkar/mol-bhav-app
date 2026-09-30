using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Localization;
using MolBhav.Domain.Market;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Persistence.Converters;

/// <summary>
/// Single-value value objects map to one scalar column through a converter rather than as an EF complex type:
/// the column can then be indexed (EF Core cannot index a property inside a complex type) and queries compare the
/// value object directly (<c>u.PhoneNumber == phone</c>). Multi-value objects such as <see cref="Money"/> stay complex types.
/// Rehydration re-runs the domain factory, so a corrupted row fails loudly instead of producing an invalid value object.
/// </summary>
internal static class ValueObjectConverters
{
    public static readonly ValueConverter<PhoneNumber, string> PhoneNumberConverter = new(
        phone => phone.Value,
        value => Rehydrate(PhoneNumber.Create(value), value));

    public static readonly ValueConverter<LanguageCode, string> LanguageCodeConverter = new(
        language => language.Value,
        value => Rehydrate(LanguageCode.Create(value), value));

    public static readonly ValueConverter<ProcurementCategoryCode, string> ProcurementCategoryCodeConverter = new(
        code => code.Value,
        value => Rehydrate(ProcurementCategoryCode.Create(value), value));

    public static readonly ValueConverter<CatalogCode, string> CatalogCodeConverter = new(
        code => code.Value,
        value => Rehydrate(CatalogCode.Create(value), value));

    public static readonly ValueConverter<MarketCode, string> MarketCodeConverter = new(
        code => code.Value,
        value => Rehydrate(MarketCode.Create(value), value));

    public static readonly ValueConverter<LocalizationKey, string> LocalizationKeyConverter = new(
        key => key.Value,
        value => Rehydrate(LocalizationKey.Create(value), value));

    private static T Rehydrate<T>(Result<T> result, string storedValue) =>
        result.IsSuccess
            ? result.Value
            : throw new InvalidOperationException(
                $"Stored value '{storedValue}' is not a valid {typeof(T).Name} ({result.Error.Code}). The row is corrupt.");
}
