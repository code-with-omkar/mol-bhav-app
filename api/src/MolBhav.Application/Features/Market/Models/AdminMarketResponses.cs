namespace MolBhav.Application.Features.Market.Models;

// Admin read models: inactive items included.

public sealed record AdminDistrictResponse(Guid Id, string Name, bool IsActive);

public sealed record AdminStateResponse(Guid Id, string Name, string Code, bool IsActive, IReadOnlyList<AdminDistrictResponse> Districts);

public sealed record AdminMandiResponse(Guid Id, string Code, string Name, Guid DistrictId, string DistrictName, bool IsActive);

public sealed record AdminSupplierResponse(Guid Id, string Code, string Name, Guid DistrictId, string DistrictName, string? ContactPhone, bool IsActive);
