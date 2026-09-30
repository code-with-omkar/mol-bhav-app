using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Procurement.CreateRequirement;

public sealed record CreateRequirementCommand(
    Guid ProductId,
    Guid? VariantId,
    decimal Quantity,
    Guid UnitId,
    Guid? TargetDistrictId,
    decimal? TargetPrice) : ICommand<CreatedResponse>;
