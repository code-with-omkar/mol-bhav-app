using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Pricing.Events;

namespace MolBhav.Domain.Pricing;

/// <summary>
/// One observed price for a product, at a location, on a date, from a source (BRD §9/§10/§19 — PriceRecords and
/// PriceHistory are unified into a single insert-mostly, date-keyed table: a record already <em>is</em> a point of
/// history, so a separate history table would just duplicate it). Immutable once created — a correction is voided
/// (<see cref="Void"/>) and re-ingested, never edited in place, so trend/comparison reads never see a silently
/// changed number.
/// </summary>
public sealed class PriceRecord : AggregateRoot<Guid>, IAuditableEntity
{
    private PriceRecord(
        Guid id,
        Guid productId,
        Guid? variantId,
        Guid unitId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        Guid priceSourceId,
        decimal? minPrice,
        decimal? maxPrice,
        decimal modalPrice,
        decimal? arrivalQuantity,
        DateOnly recordDate)
        : base(id)
    {
        ProductId = productId;
        VariantId = variantId;
        UnitId = unitId;
        LocationKind = locationKind;
        MandiId = mandiId;
        SupplierId = supplierId;
        PriceSourceId = priceSourceId;
        MinPrice = minPrice;
        MaxPrice = maxPrice;
        ModalPrice = modalPrice;
        ArrivalQuantity = arrivalQuantity;
        RecordDate = recordDate;
        IsVoided = false;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private PriceRecord()
    {
    }

    public Guid ProductId { get; private set; }

    public Guid? VariantId { get; private set; }

    /// <summary>The unit these amounts are recorded in (₹/quintal, ₹/bag, …) — comparisons convert through <see cref="Catalog.UnitOfMeasure.ConversionFactorTo"/>.</summary>
    public Guid UnitId { get; private set; }

    public LocationKind LocationKind { get; private set; }

    /// <summary>Set when <see cref="LocationKind"/> is <see cref="Pricing.LocationKind.Mandi"/>; null otherwise.</summary>
    public Guid? MandiId { get; private set; }

    /// <summary>Set when <see cref="LocationKind"/> is <see cref="Pricing.LocationKind.Supplier"/>; null otherwise.</summary>
    public Guid? SupplierId { get; private set; }

    public Guid PriceSourceId { get; private set; }

    /// <summary>Agriculture mandi feeds carry min/max/modal; a construction benchmark feed may carry only <see cref="ModalPrice"/>.</summary>
    public decimal? MinPrice { get; private set; }

    public decimal? MaxPrice { get; private set; }

    public decimal ModalPrice { get; private set; }

    /// <summary>Agriculture only (quintals arrived that day); null for construction.</summary>
    public decimal? ArrivalQuantity { get; private set; }

    /// <summary>The date the price is for — not the ingestion timestamp (<see cref="IAuditableEntity.CreatedAtUtc"/>).</summary>
    public DateOnly RecordDate { get; private set; }

    /// <summary>True for a record an admin has flagged as bad data (e.g. a source glitch); excluded from mobile reads but kept for audit.</summary>
    public bool IsVoided { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>
    /// The caller (application layer) guarantees <paramref name="productId"/>/<paramref name="variantId"/>/<paramref name="unitId"/>
    /// and the location id exist — they belong to other modules; the database FKs are the backstop.
    /// </summary>
    public static Result<PriceRecord> Create(
        Guid productId,
        Guid? variantId,
        Guid unitId,
        LocationKind locationKind,
        Guid? mandiId,
        Guid? supplierId,
        Guid priceSourceId,
        decimal? minPrice,
        decimal? maxPrice,
        decimal modalPrice,
        decimal? arrivalQuantity,
        DateOnly recordDate)
    {
        if (productId == Guid.Empty || unitId == Guid.Empty || priceSourceId == Guid.Empty)
        {
            return Error.Validation("PriceRecord.ReferenceRequired", "Product, unit and price source are required.");
        }

        var locationCheck = ValidateLocation(locationKind, mandiId, supplierId);
        if (locationCheck.IsFailure)
        {
            return Result.Failure<PriceRecord>(locationCheck.Error);
        }

        var amountsCheck = ValidateAmounts(minPrice, maxPrice, modalPrice, arrivalQuantity);
        if (amountsCheck.IsFailure)
        {
            return Result.Failure<PriceRecord>(amountsCheck.Error);
        }

        if (recordDate > DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(1)))
        {
            return Error.Validation("PriceRecord.FutureDate", "Record date cannot be in the future.");
        }

        var record = new PriceRecord(
            Guid.CreateVersion7(),
            productId,
            variantId,
            unitId,
            locationKind,
            mandiId,
            supplierId,
            priceSourceId,
            minPrice,
            maxPrice,
            modalPrice,
            arrivalQuantity,
            recordDate);

        record.RaiseDomainEvent(new PriceRecordedDomainEvent(
            record.Id,
            productId,
            variantId,
            locationKind,
            mandiId,
            supplierId,
            modalPrice,
            recordDate));

        return record;
    }

    /// <summary>
    /// True when a re-fetched row carries exactly these figures — ingestion then leaves the record alone instead of
    /// voiding and re-creating it (which would raise a second <see cref="PriceRecordedDomainEvent"/> for the same day).
    /// </summary>
    public bool HasSameFigures(decimal? minPrice, decimal? maxPrice, decimal modalPrice, decimal? arrivalQuantity) =>
        MinPrice == minPrice && MaxPrice == maxPrice && ModalPrice == modalPrice && ArrivalQuantity == arrivalQuantity;

    /// <summary>Marks a bad record so reads stop surfacing it. Never physically deleted — ingestion provenance is kept.</summary>
    public void Void()
    {
        IsVoided = true;
    }

    private static Result ValidateLocation(LocationKind locationKind, Guid? mandiId, Guid? supplierId)
    {
        var hasMandi = mandiId is { } m && m != Guid.Empty;
        var hasSupplier = supplierId is { } s && s != Guid.Empty;

        return locationKind switch
        {
            LocationKind.Mandi when !hasMandi =>
                Error.Validation("PriceRecord.MandiRequired", "Mandi is required for an agriculture price record."),
            LocationKind.Mandi when hasSupplier =>
                Error.Validation("PriceRecord.SupplierNotAllowed", "Supplier must not be set for a mandi price record."),
            LocationKind.Supplier when !hasSupplier =>
                Error.Validation("PriceRecord.SupplierRequired", "Supplier is required for a construction price record."),
            LocationKind.Supplier when hasMandi =>
                Error.Validation("PriceRecord.MandiNotAllowed", "Mandi must not be set for a supplier price record."),
            LocationKind.Mandi or LocationKind.Supplier => Result.Success(),
            _ => Error.Validation("PriceRecord.InvalidLocationKind", "Unknown location kind."),
        };
    }

    private static Result ValidateAmounts(decimal? minPrice, decimal? maxPrice, decimal modalPrice, decimal? arrivalQuantity)
    {
        if (!PricingRules.IsValidAmount(modalPrice) || modalPrice <= 0m)
        {
            return Error.Validation("PriceRecord.InvalidModalPrice", "Modal price must be positive with at most 2 decimal places.");
        }

        if (minPrice is { } min && (!PricingRules.IsValidAmount(min) || min > modalPrice))
        {
            return Error.Validation("PriceRecord.InvalidMinPrice", "Min price must be a non-negative amount not exceeding the modal price.");
        }

        if (maxPrice is { } max && (!PricingRules.IsValidAmount(max) || max < modalPrice))
        {
            return Error.Validation("PriceRecord.InvalidMaxPrice", "Max price must be a non-negative amount not less than the modal price.");
        }

        if (arrivalQuantity is { } qty && (qty < 0m || decimal.Round(qty, PricingRules.QuantityScale) != qty))
        {
            return Error.Validation("PriceRecord.InvalidArrivalQuantity", "Arrival quantity must be non-negative with at most 2 decimal places.");
        }

        return Result.Success();
    }
}
