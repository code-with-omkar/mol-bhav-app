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
        DateOnly beforeDate,
        Guid recordId,
        CancellationToken cancellationToken = default) =>
        Set
            .Where(r => r.ProductId == productId
                && r.VariantId == variantId
                && r.LocationKind == locationKind
                && r.MandiId == mandiId
                && r.SupplierId == supplierId
                && r.RecordDate < beforeDate
                && r.Id != recordId
                && !r.IsVoided)
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
}
