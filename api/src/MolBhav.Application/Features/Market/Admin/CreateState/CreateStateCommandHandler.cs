using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.CreateState;

internal sealed class CreateStateCommandHandler(IStateRepository states) : ICommandHandler<CreateStateCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateStateCommand request, CancellationToken cancellationToken)
    {
        // Friendly pre-check; the unique index is the race-proof backstop (→ 409).
        if (await states.NameExistsAsync(request.Name.Trim(), cancellationToken))
        {
            return Error.Conflict("State.NameTaken", $"State '{request.Name}' already exists.");
        }

        if (await states.CodeExistsAsync(request.Code.Trim().ToUpperInvariant(), cancellationToken))
        {
            return Error.Conflict("State.CodeTaken", $"State code '{request.Code}' already exists.");
        }

        var state = State.Create(request.Name, request.Code);
        if (state.IsFailure)
        {
            return Result.Failure<CreatedResponse>(state.Error);
        }

        states.Add(state.Value);
        return new CreatedResponse(state.Value.Id);
    }
}
