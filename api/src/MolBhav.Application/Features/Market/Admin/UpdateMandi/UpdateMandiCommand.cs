using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Market.Admin.UpdateMandi;

/// <summary>Full replacement of editable fields. The code is immutable (ingestion adapters reference it).</summary>
public sealed record UpdateMandiCommand(Guid MandiId, Guid DistrictId, string Name, bool? IsActive) : ICommand;
