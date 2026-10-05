using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Pricing.Admin.Common;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.Admin.CreatePriceSource;

internal sealed class CreatePriceSourceCommandHandler(IPriceSourceRepository sources, IProcurementCategoryRepository categories)
    : ICommandHandler<CreatePriceSourceCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreatePriceSourceCommand request, CancellationToken cancellationToken)
    {
        // Friendly pre-check; the unique index is the race-proof backstop (→ 409).
        if (await sources.CodeExistsAsync(request.Code.Trim().ToLowerInvariant(), cancellationToken))
        {
            return Error.Conflict("PriceSource.CodeTaken", $"Price source code '{request.Code}' already exists.");
        }

        var categoryId = await PriceSourceCategoryResolver.ResolveAsync(categories, request.CategoryCode, cancellationToken);
        if (categoryId.IsFailure)
        {
            return Result.Failure<CreatedResponse>(categoryId.Error);
        }

        var source = PriceSource.Create(request.Code, request.Name, categoryId.Value);
        if (source.IsFailure)
        {
            return Result.Failure<CreatedResponse>(source.Error);
        }

        sources.Add(source.Value);
        return new CreatedResponse(source.Value.Id);
    }
}
