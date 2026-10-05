using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.Models;

public sealed record AdminPriceSourceResponse(Guid Id, string Code, string Name, bool IsActive, string CategoryCode);

public sealed record AdminPriceRecordResponse(
    Guid Id,
    Guid ProductId,
    string ProductCode,
    Guid? VariantId,
    string? VariantCode,
    LocationKind LocationKind,
    Guid LocationId,
    string LocationName,
    Guid UnitId,
    string UnitCode,
    decimal? MinPrice,
    decimal? MaxPrice,
    decimal ModalPrice,
    decimal? ArrivalQuantity,
    DateOnly RecordDate,
    Guid PriceSourceId,
    string SourceCode,
    bool IsVoided);
