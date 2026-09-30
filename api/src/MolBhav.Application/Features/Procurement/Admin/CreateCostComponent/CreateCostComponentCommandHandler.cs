using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Features.Procurement.Admin.CreateCostComponent;

internal sealed class CreateCostComponentCommandHandler(ICostComponentRepository costComponents) : ICommandHandler<CreateCostComponentCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateCostComponentCommand request, CancellationToken cancellationToken)
    {
        if (await costComponents.CodeExistsAsync(request.Code!.Trim(), cancellationToken))
        {
            return Error.Conflict("CostComponent.CodeAlreadyExists", "A cost component with this code already exists.");
        }

        var component = CostComponent.Create(request.Code, request.Name, request.ComponentType!.Value, request.Value!.Value);
        if (component.IsFailure)
        {
            return Result.Failure<CreatedResponse>(component.Error);
        }

        costComponents.Add(component.Value);
        return new CreatedResponse(component.Value.Id);
    }
}
