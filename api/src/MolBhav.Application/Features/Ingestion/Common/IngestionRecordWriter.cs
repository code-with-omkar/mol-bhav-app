using System.Text.Json;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Market;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Ingestion.Common;

/// <summary>
/// Stores a batch of normalized rows for one <see cref="DataIngestionJob"/> — shared by adapter runs (API / scheduler /
/// backfill) and file uploads, so every path resolves codes, de-duplicates and reports errors identically. A row whose
/// product belongs to a different procurement category than the source is rejected (an Agmarknet file cannot price cement,
/// a CPWD sheet cannot price onions). Rows that fail
/// become <see cref="DataIngestionError"/>s; re-fetched identical rows are counted as unchanged; corrected rows void the
/// old record and store a new one. The caller's command transaction (<c>UnitOfWorkBehavior</c>) commits it all.
/// </summary>
internal sealed class IngestionRecordWriter(
    IDataIngestionErrorRepository errors,
    IPriceRecordRepository records,
    IProductRepository products,
    IProcurementCategoryRepository categories,
    IMandiRepository mandis,
    ISupplierRepository suppliers,
    TimeProvider timeProvider)
{
    /// <summary>
    /// Writes <paramref name="rows"/> for a source of category <paramref name="categoryId"/>, records per-row errors
    /// against <paramref name="job"/>, and returns the counts.
    /// </summary>
    /// <remarks>
    /// With <paramref name="skipRowsOutsideCatalog"/> a row whose product, mandi or supplier is not in the catalog is
    /// dropped and only counted (<see cref="IngestionWriteCounts.Skipped"/>) instead of stored as an error. Meant for a
    /// national feed such as Agmarknet, where ~99% of rows are commodities and markets the app does not track; uploads
    /// leave it off because their per-row errors are the admin's mapping to-do list. A row that resolves to a catalog
    /// product and location but fails for another reason (e.g. an unknown variety) is still an error.
    /// <para>
    /// With <paramref name="fallbackToProductForUnknownVariety"/> a row whose variety is not one of the product's active
    /// variants (or cannot be a code) is stored as the product's no-variant price instead of failing — a feed names
    /// many more varieties than a catalog tracks. This runs as a second pass, after every row that matched a variant
    /// or had none, so a real generic row is never displaced by whichever unknown variety came first. Unknown
    /// varieties of one product/location/day collapse into a single record (the first is kept); the rest are counted
    /// as skipped, not reported as duplicates.
    /// </para>
    /// </remarks>
    public async Task<IngestionWriteCounts> WriteAsync(
        DataIngestionJob job,
        Guid categoryId,
        IReadOnlyCollection<IngestedPriceRecord> rows,
        CancellationToken cancellationToken,
        bool skipRowsOutsideCatalog = false,
        bool fallbackToProductForUnknownVariety = false)
    {
        ArgumentNullException.ThrowIfNull(job);
        ArgumentNullException.ThrowIfNull(rows);

        // One lookup per batch; a product is in the category when its sub-category is.
        var allowedSubCategories = rows.Count == 0
            ? new HashSet<Guid>()
            : await categories.GetSubCategoryIdsAsync(categoryId, cancellationToken);

        var persisted = 0;
        var unchanged = 0;
        var failed = 0;
        var skipped = 0;
        var seenThisRun = new HashSet<RecordKey>();
        List<IngestedPriceRecord>? unknownVariety = null;

        void Tally(IngestedPriceRecord raw, Result<RowOutcome> outcome, bool fromFallback)
        {
            switch (outcome)
            {
                case { IsFailure: true } failure when skipRowsOutsideCatalog && OutsideCatalogErrors.Contains(failure.Error.Code):
                    skipped++;
                    break;
                case { IsFailure: true } failure when fromFallback && failure.Error.Code == "Ingestion.DuplicateInSource":
                    skipped++; // another unknown variety of the same product/location/day already supplied the price
                    break;
                case { IsFailure: true } failure:
                    failed++;
                    RecordError(job, JsonSerializer.Serialize(raw), failure.Error.Description);
                    break;
                case { Value: RowOutcome.Unchanged }:
                    unchanged++;
                    break;
                default:
                    persisted++;
                    break;
            }
        }

        foreach (var raw in rows)
        {
            var outcome = await ApplyAsync(raw, job.PriceSourceId, allowedSubCategories, seenThisRun, ignoreVariety: false, cancellationToken);
            if (fallbackToProductForUnknownVariety && outcome is { IsFailure: true } failure && UnknownVarietyErrors.Contains(failure.Error.Code))
            {
                (unknownVariety ??= []).Add(raw);
                continue;
            }

            Tally(raw, outcome, fromFallback: false);
        }

        foreach (var raw in unknownVariety ?? [])
        {
            var outcome = await ApplyAsync(raw, job.PriceSourceId, allowedSubCategories, seenThisRun, ignoreVariety: true, cancellationToken);
            Tally(raw, outcome, fromFallback: true);
        }

        // Skipped rows are not "fetched" for the job's counts: fetched = persisted + unchanged + failed.
        return new IngestionWriteCounts(rows.Count - skipped, persisted, unchanged, failed, skipped);
    }

    /// <summary>Failures that mean "the product is ours but this variety is not" (see <c>fallbackToProductForUnknownVariety</c>).</summary>
    private static readonly HashSet<string> UnknownVarietyErrors = ["Ingestion.VariantNotFound", "Ingestion.VariantCodeInvalid"];

    /// <summary>Failures that mean "this product or location is not one we track" (see <c>skipRowsOutsideCatalog</c>).</summary>
    private static readonly HashSet<string> OutsideCatalogErrors =
    [
        "Ingestion.ProductNotFound",
        "Ingestion.ProductCodeInvalid",
        "Ingestion.MandiNotFound",
        "Ingestion.SupplierNotFound",
        "Ingestion.LocationCodeInvalid",
    ];

    /// <summary>Records a row the caller could not even turn into an <see cref="IngestedPriceRecord"/> (e.g. a bad CSV line).</summary>
    public void RecordError(DataIngestionJob job, string rawPayloadJson, string message)
    {
        ArgumentNullException.ThrowIfNull(job);
        var error = DataIngestionError.Create(job.Id, rawPayloadJson, message, timeProvider.GetUtcNow());
        if (error.IsSuccess)
        {
            errors.Add(error.Value);
        }
    }

    /// <summary>Identity of one price row; the same key twice in one fetch is a source-side duplicate.</summary>
    private readonly record struct RecordKey(
        Guid ProductId, Guid? VariantId, Guid UnitId, LocationKind LocationKind, Guid? MandiId, Guid? SupplierId, DateOnly RecordDate);

    private enum RowOutcome
    {
        /// <summary>A new record, or a corrected one (the previous record was voided).</summary>
        Stored,

        /// <summary>Already stored with the same figures — a re-run or backfill of a day already pulled.</summary>
        Unchanged,
    }

    /// <summary>
    /// Resolves one adapter row onto internal ids and stores it — never throws; every failure mode (bad code format,
    /// unknown product/variant/location, domain validation) comes back as a <see cref="Result"/> so the caller records
    /// one <see cref="DataIngestionError"/> and continues. Re-fetching a day is idempotent: identical figures are left
    /// alone, changed figures void the old record and store a new one (records are never edited in place).
    /// </summary>
    private async Task<Result<RowOutcome>> ApplyAsync(
        IngestedPriceRecord raw,
        Guid priceSourceId,
        IReadOnlySet<Guid> allowedSubCategories,
        HashSet<RecordKey> seenThisRun,
        bool ignoreVariety,
        CancellationToken cancellationToken)
    {
        var productCode = CatalogCode.Create(raw.ProductCode);
        if (productCode.IsFailure)
        {
            // Same message as before, but its own code: a name that cannot be a catalog code is not a catalog product.
            return Error.Validation("Ingestion.ProductCodeInvalid", productCode.Error.Description);
        }

        var product = await products.GetByCodeAsync(productCode.Value, cancellationToken);
        if (product is null)
        {
            return Error.Validation("Ingestion.ProductNotFound", $"No active product with code '{raw.ProductCode}'.");
        }

        if (!allowedSubCategories.Contains(product.SubCategoryId))
        {
            return Error.Validation(
                "Ingestion.ProductOutsideCategory",
                $"Product '{raw.ProductCode}' is not in this source's category; use a source of the product's category.");
        }

        Guid? variantId = null;
        if (!ignoreVariety && !string.IsNullOrWhiteSpace(raw.VariantCode))
        {
            var variantCode = CatalogCode.Create(raw.VariantCode);
            if (variantCode.IsFailure)
            {
                return Error.Validation("Ingestion.VariantCodeInvalid", variantCode.Error.Description);
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
            return Error.Validation("Ingestion.LocationCodeInvalid", locationCode.Error.Description);
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
        // Not yet saved, so the database cannot see an earlier row from this same fetch — check in memory first.
        // (e.g. Agmarknet lists FAQ and non-FAQ grades of one variety; both map to the same record.)
        if (!seenThisRun.Add(new RecordKey(product.Id, variantId, product.DefaultUnitId, raw.LocationKind, mandiId, supplierId, raw.RecordDate)))
        {
            return Error.Conflict("Ingestion.DuplicateInSource", "The source sent this product/location/date more than once; the first row was kept.");
        }

        var existing = await records.FindActiveAsync(
            product.Id, variantId, product.DefaultUnitId, raw.LocationKind, mandiId, supplierId, priceSourceId, raw.RecordDate, cancellationToken);
        if (existing is not null && existing.HasSameFigures(raw.MinPrice, raw.MaxPrice, raw.ModalPrice, raw.ArrivalQuantity))
        {
            return RowOutcome.Unchanged;
        }

        var created = PriceRecord.Create(
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
        if (created.IsFailure)
        {
            return Result.Failure<RowOutcome>(created.Error);
        }

        // The source corrected this day's figures: keep the old row for provenance, stop serving it.
        existing?.Void();
        records.Add(created.Value);
        return RowOutcome.Stored;
    }
}

/// <summary>Rows handed to the writer and what became of them.</summary>
internal readonly record struct IngestionWriteCounts(int Fetched, int Persisted, int Unchanged, int Failed, int Skipped = 0);
