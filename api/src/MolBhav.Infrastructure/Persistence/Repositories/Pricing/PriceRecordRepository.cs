using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Persistence.Repositories;

namespace MolBhav.Infrastructure.Persistence.Repositories.Pricing;

internal sealed class PriceRecordRepository(MolBhavDbContext dbContext) : Repository<PriceRecord, Guid>(dbContext), IPriceRecordRepository
{
    public Task<PriceRecord?> GetPreviousAsync(
        Guid productId,
        Guid? variantId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        DateOnly recordDate,
        Guid recordId,
        CancellationToken cancellationToken = default) =>
        Set.AsNoTracking()
            .Where(r => r.ProductId == productId
                && r.VariantId == variantId
                && r.LocationKind == locationKind
                && r.MandiId == mandiId
                && r.SupplierId == supplierId
                && r.Id != recordId
                // Same day: the record this one corrected (voided in the same save). Earlier days: live records only.
                && ((r.RecordDate == recordDate && r.IsVoided) || (r.RecordDate < recordDate && !r.IsVoided)))
            .OrderByDescending(r => r.RecordDate)
            .ThenByDescending(r => r.CreatedAtUtc)
            .FirstOrDefaultAsync(cancellationToken);

    public Task<bool> DuplicateExistsAsync(
        Guid productId,
        Guid? variantId,
        Guid unitId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        Guid priceSourceId,
        DateOnly recordDate,
        CancellationToken cancellationToken = default) =>
        Set.AnyAsync(
            r => r.ProductId == productId
                && r.VariantId == variantId
                && r.UnitId == unitId
                && r.LocationKind == locationKind
                && r.MandiId == mandiId
                && r.SupplierId == supplierId
                && r.PriceSourceId == priceSourceId
                && r.RecordDate == recordDate
                && !r.IsVoided,
            cancellationToken);

    public Task<PriceRecord?> FindActiveAsync(
        Guid productId,
        Guid? variantId,
        Guid unitId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        Guid priceSourceId,
        DateOnly recordDate,
        CancellationToken cancellationToken = default) =>
        Set.FirstOrDefaultAsync(
            r => r.ProductId == productId
                && r.VariantId == variantId
                && r.UnitId == unitId
                && r.LocationKind == locationKind
                && r.MandiId == mandiId
                && r.SupplierId == supplierId
                && r.PriceSourceId == priceSourceId
                && r.RecordDate == recordDate
                && !r.IsVoided,
            cancellationToken);
}
