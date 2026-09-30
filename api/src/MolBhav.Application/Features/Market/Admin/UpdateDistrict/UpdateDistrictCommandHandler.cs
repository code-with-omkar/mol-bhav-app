using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.Admin.UpdateDistrict;

internal sealed class UpdateDistrictCommandHandler(IStateRepository states) : ICommandHandler<UpdateDistrictCommand>
{
    public async Task<Result> Handle(UpdateDistrictCommand request, CancellationToken cancellationToken)
    {
        var state = await states.GetByIdAsync(request.StateId, cancellationToken);
        return state is null
            ? Error.NotFound("State.NotFound", "State not found.")
            : state.UpdateDistrict(request.DistrictId, request.Name, request.IsActive!.Value);
    }
}
