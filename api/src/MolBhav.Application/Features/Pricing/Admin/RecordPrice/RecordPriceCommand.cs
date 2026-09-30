using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.Admin.RecordPrice;

public sealed record RecordPriceCommand(
    Guid ProductId,
    Guid? VariantId,
    Guid UnitId,
    LocationKind? LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    Guid PriceSourceId,
    decimal? MinPrice,
    decimal? MaxPrice,
    decimal ModalPrice,
    decimal? ArrivalQuantity,
    DateOnly RecordDate) : ICommand<CreatedResponse>;
