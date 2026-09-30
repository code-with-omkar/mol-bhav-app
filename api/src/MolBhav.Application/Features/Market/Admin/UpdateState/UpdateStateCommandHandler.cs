using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.Admin.UpdateState;

internal sealed class UpdateStateCommandHandler(IStateRepository states) : ICommandHandler<UpdateStateCommand>
{
    public async Task<Result> Handle(UpdateStateCommand request, CancellationToken cancellationToken)
    {
        var state = await states.GetByIdAsync(request.StateId, cancellationToken);
        return state is null
            ? Error.NotFound("State.NotFound", "State not found.")
            : state.Update(request.Name, request.IsActive!.Value);
    }
}
