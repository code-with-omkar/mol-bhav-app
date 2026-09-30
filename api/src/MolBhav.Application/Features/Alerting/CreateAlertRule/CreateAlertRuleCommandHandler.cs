using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Alerting.CreateAlertRule;

internal sealed class CreateAlertRuleCommandHandler(
    IAlertRuleRepository alertRules,
    IProductRepository products,
    IMandiRepository mandis,
    ISupplierRepository suppliers,
    ICurrentUser currentUser) : ICommandHandler<CreateAlertRuleCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateAlertRuleCommand request, CancellationToken cancellationToken)
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

        if (request.MandiId is { } mandiId && await mandis.GetByIdAsync(mandiId, cancellationToken) is null)
        {
            return Error.NotFound("Mandi.NotFound", "Mandi not found.");
        }

        if (request.SupplierId is { } supplierId && await suppliers.GetByIdAsync(supplierId, cancellationToken) is null)
        {
            return Error.NotFound("Supplier.NotFound", "Supplier not found.");
        }

        var rule = AlertRule.Create(
            userId,
            request.ProductId,
            request.VariantId,
            request.LocationKind,
            request.MandiId,
            request.SupplierId,
            request.ThresholdType!.Value,
            request.ThresholdPercent,
            request.ThresholdPrice);

        if (rule.IsFailure)
        {
            return Result.Failure<CreatedResponse>(rule.Error);
        }

        alertRules.Add(rule.Value);
        return new CreatedResponse(rule.Value.Id);
    }
}
