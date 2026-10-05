using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Pricing.Admin.UpdatePriceSource;

/// <summary>The code is immutable (ingestion adapters reference it); name, active flag and category can change.</summary>
public sealed record UpdatePriceSourceCommand(Guid PriceSourceId, string Name, bool? IsActive, string CategoryCode) : ICommand;
