using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Pricing.Admin.VoidPriceRecord;

/// <summary>Marks a record voided (e.g. entered in error) without deleting it — history stays intact.</summary>
public sealed record VoidPriceRecordCommand(Guid PriceRecordId) : ICommand;
