using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Procurement.Models;

namespace MolBhav.Application.Features.Procurement.GetMyRequirements;

public sealed record GetMyRequirementsQuery : IQuery<IReadOnlyList<ProcurementRequirementResponse>>;
