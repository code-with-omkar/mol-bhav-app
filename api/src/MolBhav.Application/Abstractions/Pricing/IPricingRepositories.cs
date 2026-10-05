using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Abstractions.Pricing;

public interface IPriceSourceRepository : IRepository<PriceSource, Guid>
{
    Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default);

    /// <summary>Every active source.</summary>
    Task<IReadOnlyList<PriceSource>> GetActiveAsync(CancellationToken cancellationToken = default);

    /// <summary>Ids of the active sources in one procurement category, by name — the category "run all" set.</summary>
    Task<IReadOnlyList<Guid>> GetActiveIdsByCategoryAsync(Guid categoryId, CancellationToken cancellationToken = default);
}

public interface IPriceRecordRepository : IRepository<PriceRecord, Guid>
{
    /// <summary>
    /// The live (not voided) record for exactly this product/variant/unit/location/source/date, tracked — ingestion
    /// re-runs compare against it and void it when the source corrected a figure.
    /// </summary>
    Task<PriceRecord?> FindActiveAsync(
        Guid productId,
        Guid? variantId,
        Guid unitId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        Guid priceSourceId,
        DateOnly recordDate,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Friendly pre-check only — nullable variant/mandi/supplier columns mean a plain unique DB index would not catch
    /// every duplicate (Postgres treats NULLs as distinct), so this is the sole guard until the Ingestion module adds
    /// a proper idempotency key per source.
    /// </summary>
    Task<bool> DuplicateExistsAsync(
        Guid productId,
        Guid? variantId,
        Guid unitId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        Guid priceSourceId,
        DateOnly recordDate,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// The price a new record should be compared with (any source) — used by Alerting to compute the move it represents:
    /// the latest record for the same product/variant/location on the same <paramref name="recordDate"/> that it
    /// replaced (voided by a correction — only one active record per day exists), otherwise the most recent non-voided
    /// record on an earlier date.
    /// </summary>
    Task<PriceRecord?> GetPreviousAsync(
        Guid productId,
        Guid? variantId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        DateOnly recordDate,
        Guid recordId,
        CancellationToken cancellationToken = default);
}
