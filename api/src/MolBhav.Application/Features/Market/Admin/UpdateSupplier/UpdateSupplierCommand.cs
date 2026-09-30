using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Market.Admin.UpdateSupplier;

/// <summary>Full replacement of editable fields. The code is immutable (ingestion adapters reference it).</summary>
public sealed record UpdateSupplierCommand(Guid SupplierId, Guid DistrictId, string Name, string? ContactPhone, bool? IsActive) : ICommand;
