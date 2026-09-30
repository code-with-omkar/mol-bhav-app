using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Procurement;

namespace MolBhav.Application.Features.Procurement.Admin.CreateCostComponent;

public sealed record CreateCostComponentCommand(string? Code, string? Name, CostComponentType? ComponentType, decimal? Value)
    : ICommand<CreatedResponse>;
