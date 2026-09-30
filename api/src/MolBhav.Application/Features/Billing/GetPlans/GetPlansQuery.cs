using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.GetPlans;

public sealed record GetPlansQuery : IQuery<IReadOnlyList<PlanResponse>>;
