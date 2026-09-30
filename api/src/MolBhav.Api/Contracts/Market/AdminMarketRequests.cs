namespace MolBhav.Api.Contracts.Market;

// Admin portal request bodies. PUTs are full replacements. isActive is nullable so a missing field reaches
// FluentValidation instead of silently binding to false — an omitted isActive must never deactivate an item.

public sealed record CreateStateRequest(string? Name, string? Code);

public sealed record UpdateStateRequest(string? Name, bool? IsActive);

public sealed record AddDistrictRequest(string? Name);

public sealed record UpdateDistrictRequest(string? Name, bool? IsActive);

/// <param name="Code">Immutable, e.g. <c>apmc-pune</c>.</param>
/// <param name="DistrictId">The mandi's district.</param>
/// <param name="Name">Display name.</param>
public sealed record CreateMandiRequest(string? Code, Guid? DistrictId, string? Name);

public sealed record UpdateMandiRequest(Guid? DistrictId, string? Name, bool? IsActive);

/// <param name="Code">Immutable, e.g. <c>hub-nagpur-01</c>.</param>
/// <param name="DistrictId">The supplier's district.</param>
/// <param name="Name">Display name.</param>
/// <param name="ContactPhone">Optional, free text.</param>
public sealed record CreateSupplierRequest(string? Code, Guid? DistrictId, string? Name, string? ContactPhone);

public sealed record UpdateSupplierRequest(Guid? DistrictId, string? Name, string? ContactPhone, bool? IsActive);
