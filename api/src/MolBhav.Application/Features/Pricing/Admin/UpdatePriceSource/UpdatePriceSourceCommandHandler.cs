using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Pricing.Admin.UpdatePriceSource;

internal sealed class UpdatePriceSourceCommandHandler(IPriceSourceRepository sources) : ICommandHandler<UpdatePriceSourceCommand>
{
    public async Task<Result> Handle(UpdatePriceSourceCommand request, CancellationToken cancellationToken)
    {
        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        return source.Update(request.Name, request.IsActive!.Value);
    }
}
