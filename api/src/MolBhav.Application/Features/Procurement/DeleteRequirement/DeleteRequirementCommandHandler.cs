using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Procurement;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Procurement.DeleteRequirement;

internal sealed class DeleteRequirementCommandHandler(IProcurementRequirementRepository requirements, ICurrentUser currentUser)
    : ICommandHandler<DeleteRequirementCommand>
{
    public async Task<Result> Handle(DeleteRequirementCommand request, CancellationToken cancellationToken)
    {
        var requirement = await requirements.GetByIdAsync(request.RequirementId, cancellationToken);
        if (requirement is null || requirement.UserId != currentUser.GetRequiredUserId())
        {
            return Error.NotFound("ProcurementRequirement.NotFound", "Requirement not found.");
        }

        requirements.Remove(requirement);
        return Result.Success();
    }
}
