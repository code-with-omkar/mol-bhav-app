using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Abstractions.Pricing;

public interface IPriceSourceRepository : IRepository<PriceSource, Guid>
{
    Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default);

    /// <summary>Every active source.</summary>
    Task<IReadOnlyList<PriceSource>> GetActiveAsync(CancellationToken cancellationToken = default);
}

public interface IPriceRecordRepository : IRepository<PriceRecord, Guid>
{
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
    /// The most recent non-voided record for the same product/variant/location strictly before <paramref name="recordId"/>'s
    /// date (any source) — used by the Alerting module to compute the percent change a new price represents.
    /// </summary>
    Task<PriceRecord?> GetPreviousAsync(
        Guid productId,
        Guid? variantId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        DateOnly beforeDate,
        Guid recordId,
        CancellationToken cancellationToken = default);
}
