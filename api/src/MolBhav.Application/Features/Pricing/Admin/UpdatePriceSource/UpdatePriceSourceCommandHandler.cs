using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Pricing.Admin.Common;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Pricing.Admin.UpdatePriceSource;

/// <summary>
/// Moving a source to another category only affects future runs and uploads (the writer checks products against the
/// source's current category); price records already stored keep pointing at their products and are not touched.
/// </summary>
internal sealed class UpdatePriceSourceCommandHandler(IPriceSourceRepository sources, IProcurementCategoryRepository categories)
    : ICommandHandler<UpdatePriceSourceCommand>
{
    public async Task<Result> Handle(UpdatePriceSourceCommand request, CancellationToken cancellationToken)
    {
        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        var categoryId = await PriceSourceCategoryResolver.ResolveAsync(categories, request.CategoryCode, cancellationToken);
        if (categoryId.IsFailure)
        {
            return categoryId.Error;
        }

        return source.Update(request.Name, request.IsActive!.Value, categoryId.Value);
    }
}
