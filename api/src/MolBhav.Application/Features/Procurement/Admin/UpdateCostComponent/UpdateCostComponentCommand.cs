using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Procurement.Admin.UpdateCostComponent;

/// <summary>The code is immutable — opportunity computations don't reference it, but changing it after historical
/// snapshots exist would be confusing in an audit trail.</summary>
public sealed record UpdateCostComponentCommand(Guid CostComponentId, string? Name, decimal? Value, bool? IsActive) : ICommand;
