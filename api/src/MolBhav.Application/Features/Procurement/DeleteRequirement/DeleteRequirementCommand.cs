using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Procurement.DeleteRequirement;

public sealed record DeleteRequirementCommand(Guid RequirementId) : ICommand;
