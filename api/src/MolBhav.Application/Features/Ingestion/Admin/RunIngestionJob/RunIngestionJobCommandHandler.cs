using System.Text.Json;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Market;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Ingestion.Admin.RunIngestionJob;

/// <summary>
/// Runs one ingestion adapter for a <c>PriceSource</c> and persists every resolvable record as a <c>PriceRecord</c>
/// (the same path <c>RecordPriceCommandHandler</c> uses for manual entry — BRD §9). A record that fails to resolve
/// or validate becomes a <see cref="DataIngestionError"/> instead of aborting the whole run, so one bad row from the
/// source never blocks the rest. All in one transaction (<c>UnitOfWorkBehavior</c>): the job, its errors, and every
/// persisted price record commit together, and each persisted record's <c>PriceRecordedDomainEvent</c> reaches the
/// outbox in the same save — Alerting evaluates it exactly as it would a manually entered price.
/// </summary>
internal sealed class RunIngestionJobCommandHandler(
    IDataIngestionJobRepository jobs,
    IDataIngestionErrorRepository errors,
    IPriceSourceRepository sources,
    IPriceRecordRepository records,
    IProductRepository products,
    IMandiRepository mandis,
    ISupplierRepository suppliers,
    IIngestionSourceAdapter adapter,
    TimeProvider timeProvider) : ICommandHandler<RunIngestionJobCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(RunIngestionJobCommand request, CancellationToken cancellationToken)
    {
        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        if (!source.IsActive)
        {
            return Error.Validation("PriceSource.Inactive", "Cannot run ingestion for an inactive price source.");
        }

        var now = timeProvider.GetUtcNow();

        var jobResult = DataIngestionJob.Start(source.Id, request.TriggerType, request.TriggeredByUserId, now);
        if (jobResult.IsFailure)
        {
            return Result.Failure<CreatedResponse>(jobResult.Error);
        }

        var job = jobResult.Value;
        jobs.Add(job);

        var fetch = await adapter.FetchAsync(new IngestionFetchRequest(source.Code, DateOnly.FromDateTime(now.UtcDateTime)), cancellationToken);
        if (!fetch.IsSuccess)
        {
            job.MarkAdapterFailed(fetch.FailureReason ?? "Ingestion adapter failed with no reason given.", timeProvider.GetUtcNow());
            return new CreatedResponse(job.Id);
        }

        var persisted = 0;
        var failed = 0;

        foreach (var raw in fetch.Records)
        {
            var resolved = await ResolveAsync(raw, source.Id, cancellationToken);
            if (resolved.IsFailure)
            {
                failed++;
                var error = DataIngestionError.Create(job.Id, JsonSerializer.Serialize(raw), resolved.Error.Description, timeProvider.GetUtcNow());
                if (error.IsSuccess)
                {
                    errors.Add(error.Value);
                }

                continue;
            }

            records.Add(resolved.Value);
            persisted++;
        }

        job.Complete(fetch.Records.Count, persisted, failed, timeProvider.GetUtcNow());
        return new CreatedResponse(job.Id);
    }

    /// <summary>
    /// Resolves one adapter row onto internal ids and creates the <see cref="PriceRecord"/> — never throws; every
    /// failure mode (bad code format, unknown product/variant/location, duplicate, domain validation) comes back as
    /// a <see cref="Result"/> so the caller can record it as one <see cref="DataIngestionError"/> and continue.
    /// </summary>
    private async Task<Result<PriceRecord>> ResolveAsync(IngestedPriceRecord raw, Guid priceSourceId, CancellationToken cancellationToken)
    {
        var productCode = CatalogCode.Create(raw.ProductCode);
        if (productCode.IsFailure)
        {
            return Result.Failure<PriceRecord>(productCode.Error);
        }

        var product = await products.GetByCodeAsync(productCode.Value, cancellationToken);
        if (product is null)
        {
            return Error.Validation("Ingestion.ProductNotFound", $"No active product with code '{raw.ProductCode}'.");
        }

        Guid? variantId = null;
        if (!string.IsNullOrWhiteSpace(raw.VariantCode))
        {
            var variantCode = CatalogCode.Create(raw.VariantCode);
            if (variantCode.IsFailure)
            {
                return Result.Failure<PriceRecord>(variantCode.Error);
            }

            var variant = product.Variants.FirstOrDefault(v => v.Code == variantCode.Value && v.IsActive);
            if (variant is null)
            {
                return Error.Validation("Ingestion.VariantNotFound", $"No active variant '{raw.VariantCode}' for product '{raw.ProductCode}'.");
            }

            variantId = variant.Id;
        }

        var locationCode = MarketCode.Create(raw.LocationCode);
        if (locationCode.IsFailure)
        {
            return Result.Failure<PriceRecord>(locationCode.Error);
        }

        Guid? mandiId = null;
        Guid? supplierId = null;
        if (raw.LocationKind == LocationKind.Mandi)
        {
            var mandi = await mandis.GetByCodeAsync(locationCode.Value, cancellationToken);
            if (mandi is null)
            {
                return Error.Validation("Ingestion.MandiNotFound", $"No active mandi with code '{raw.LocationCode}'.");
            }

            mandiId = mandi.Id;
        }
        else
        {
            var supplier = await suppliers.GetByCodeAsync(locationCode.Value, cancellationToken);
            if (supplier is null)
            {
                return Error.Validation("Ingestion.SupplierNotFound", $"No active supplier with code '{raw.LocationCode}'.");
            }

            supplierId = supplier.Id;
        }

        // Ingestion always records at the product's default unit — cross-unit source feeds are out of scope
        // (same simplification ProcurementRequirement makes; see its doc comment).
        if (await records.DuplicateExistsAsync(
            product.Id, variantId, product.DefaultUnitId, raw.LocationKind, mandiId, supplierId, priceSourceId, raw.RecordDate, cancellationToken))
        {
            return Error.Conflict("Ingestion.Duplicate", "A price record already exists for this product/location/source/date.");
        }

        return PriceRecord.Create(
            product.Id,
            variantId,
            product.DefaultUnitId,
            raw.LocationKind,
            mandiId,
            supplierId,
            priceSourceId,
            raw.MinPrice,
            raw.MaxPrice,
            raw.ModalPrice,
            raw.ArrivalQuantity,
            raw.RecordDate);
    }
}
