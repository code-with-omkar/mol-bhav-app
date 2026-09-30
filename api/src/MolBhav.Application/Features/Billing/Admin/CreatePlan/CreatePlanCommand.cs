using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.Admin.CreatePlan;

public sealed record CreatePlanCommand(string? Code, string? Name, decimal? Price, string? Currency, BillingPeriod? BillingPeriod)
    : ICommand<CreatedResponse>;
