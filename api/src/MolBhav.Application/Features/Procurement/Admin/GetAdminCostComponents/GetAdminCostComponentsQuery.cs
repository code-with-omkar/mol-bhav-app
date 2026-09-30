using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Procurement.Models;

namespace MolBhav.Application.Features.Procurement.Admin.GetAdminCostComponents;

public sealed record GetAdminCostComponentsQuery : IQuery<IReadOnlyList<AdminCostComponentResponse>>;
