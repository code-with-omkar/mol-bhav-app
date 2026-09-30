using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.Admin.RecordPrice;

/// <summary>
/// Manual/back-office price entry (the same path the future Ingestion module will call into). Validates every
/// reference explicitly rather than relying on FK failures, so the caller gets a precise 400/404/409 instead of a
/// raw constraint-violation 500.
/// </summary>
internal sealed class RecordPriceCommandHandler(
    IPriceRecordRepository records,
    IProductRepository products,
    IUnitOfMeasureRepository units,
    IMandiRepository mandis,
    ISupplierRepository suppliers,
    IPriceSourceRepository sources) : ICommandHandler<RecordPriceCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(RecordPriceCommand request, CancellationToken cancellationToken)
    {
        var product = await products.GetByIdAsync(request.ProductId, cancellationToken);
        if (product is null)
        {
            return Error.NotFound("Product.NotFound", "Product not found.");
        }

        if (request.VariantId is { } variantId && product.Variants.All(v => v.Id != variantId))
        {
            return Error.Validation("ProductVariant.NotFound", "Variant does not belong to this product.");
        }

        if (!await units.ExistsAsync(request.UnitId, cancellationToken))
        {
            return Error.Validation("UnitOfMeasure.NotFound", "Unit of measure does not exist.");
        }

        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.Validation("PriceSource.NotFound", "Price source does not exist.");
        }

        var locationKind = request.LocationKind!.Value;

        if (locationKind == LocationKind.Mandi)
        {
            if (request.MandiId is null || await mandis.GetByIdAsync(request.MandiId.Value, cancellationToken) is null)
            {
                return Error.Validation("Mandi.NotFound", "Mandi does not exist.");
            }
        }
        else if (request.SupplierId is null || await suppliers.GetByIdAsync(request.SupplierId.Value, cancellationToken) is null)
        {
            return Error.Validation("Supplier.NotFound", "Supplier does not exist.");
        }

        if (await records.DuplicateExistsAsync(
            request.ProductId, request.VariantId, request.UnitId, locationKind,
            request.MandiId, request.SupplierId, request.PriceSourceId, request.RecordDate, cancellationToken))
        {
            return Error.Conflict("PriceRecord.Duplicate", "A price record already exists for this product/location/source/date.");
        }

        var record = PriceRecord.Create(
            request.ProductId,
            request.VariantId,
            request.UnitId,
            locationKind,
            request.MandiId,
            request.SupplierId,
            request.PriceSourceId,
            request.MinPrice,
            request.MaxPrice,
            request.ModalPrice,
            request.ArrivalQuantity,
            request.RecordDate);

        if (record.IsFailure)
        {
            return Result.Failure<CreatedResponse>(record.Error);
        }

        records.Add(record.Value);
        return new CreatedResponse(record.Value.Id);
    }
}
