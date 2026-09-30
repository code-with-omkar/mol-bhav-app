using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.Admin.AddDistrict;

internal sealed class AddDistrictCommandHandler(IStateRepository states) : ICommandHandler<AddDistrictCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(AddDistrictCommand request, CancellationToken cancellationToken)
    {
        var state = await states.GetByIdAsync(request.StateId, cancellationToken);
        if (state is null)
        {
            return Error.NotFound("State.NotFound", "State not found.");
        }

        var district = state.AddDistrict(request.Name);
        return district.IsSuccess
            ? new CreatedResponse(district.Value.Id)
            : Result.Failure<CreatedResponse>(district.Error);
    }
}
