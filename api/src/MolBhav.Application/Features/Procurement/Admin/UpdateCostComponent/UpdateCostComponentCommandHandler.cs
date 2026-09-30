using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Procurement.Admin.UpdateCostComponent;

internal sealed class UpdateCostComponentCommandHandler(ICostComponentRepository costComponents) : ICommandHandler<UpdateCostComponentCommand>
{
    public async Task<Result> Handle(UpdateCostComponentCommand request, CancellationToken cancellationToken)
    {
        var component = await costComponents.GetByIdAsync(request.CostComponentId, cancellationToken);
        if (component is null)
        {
            return Error.NotFound("CostComponent.NotFound", "Cost component not found.");
        }

        return component.Update(request.Name, request.Value!.Value, request.IsActive!.Value);
    }
}
