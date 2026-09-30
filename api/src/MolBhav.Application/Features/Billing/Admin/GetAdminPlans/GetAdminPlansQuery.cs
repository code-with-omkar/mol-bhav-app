using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.Admin.GetAdminPlans;

public sealed record GetAdminPlansQuery : IQuery<IReadOnlyList<AdminPlanResponse>>;
