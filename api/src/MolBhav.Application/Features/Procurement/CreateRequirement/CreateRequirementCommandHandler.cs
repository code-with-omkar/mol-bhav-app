using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Features.Procurement.CreateRequirement;

internal sealed class CreateRequirementCommandHandler(
    IProcurementRequirementRepository requirements,
    IProductRepository products,
    IStateRepository states,
    ICurrentUser currentUser) : ICommandHandler<CreateRequirementCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateRequirementCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();

        var product = await products.GetByIdAsync(request.ProductId, cancellationToken);
        if (product is null)
        {
            return Error.NotFound("Product.NotFound", "Product not found.");
        }

        if (request.VariantId is { } variantId && product.Variants.All(v => v.Id != variantId))
        {
            return Error.Validation("ProductVariant.NotFound", "Variant does not belong to this product.");
        }

        // Cross-unit conversion at opportunity-compute time is out of scope for this pass (see ProcurementRequirement.UnitId).
        if (request.UnitId != product.DefaultUnitId)
        {
            return Error.Validation("ProcurementRequirement.UnitMismatch", "Quantity must be expressed in the product's default unit.");
        }

        if (request.TargetDistrictId is { } districtId && !await states.DistrictExistsAsync(districtId, cancellationToken))
        {
            return Error.NotFound("District.NotFound", "District not found.");
        }

        var requirement = ProcurementRequirement.Create(
            userId, request.ProductId, request.VariantId, request.Quantity, request.UnitId, request.TargetDistrictId, request.TargetPrice);

        if (requirement.IsFailure)
        {
            return Result.Failure<CreatedResponse>(requirement.Error);
        }

        requirements.Add(requirement.Value);
        return new CreatedResponse(requirement.Value.Id);
    }
}
