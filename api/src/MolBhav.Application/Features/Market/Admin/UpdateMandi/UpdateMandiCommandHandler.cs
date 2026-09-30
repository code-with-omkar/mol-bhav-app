using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.Admin.UpdateMandi;

internal sealed class UpdateMandiCommandHandler(IMandiRepository mandis, IStateRepository states) : ICommandHandler<UpdateMandiCommand>
{
    public async Task<Result> Handle(UpdateMandiCommand request, CancellationToken cancellationToken)
    {
        var mandi = await mandis.GetByIdAsync(request.MandiId, cancellationToken);
        if (mandi is null)
        {
            return Error.NotFound("Mandi.NotFound", "Mandi not found.");
        }

        if (!await states.DistrictExistsAsync(request.DistrictId, cancellationToken))
        {
            return Error.Validation("District.NotFound", "District does not exist.");
        }

        return mandi.Update(request.DistrictId, request.Name, request.IsActive!.Value);
    }
}
