namespace MolBhav.Application.Features.Market.Models;

// Mobile read models. Only active items are returned.

public sealed record StateResponse(Guid Id, string Name, string Code);

public sealed record DistrictResponse(Guid Id, string Name);

/// <summary>Agriculture pricing location (BRD §11), for the mandi/location pickers on comparison and watchlist screens.</summary>
public sealed record MandiResponse(Guid Id, string Code, string Name, Guid DistrictId, string DistrictName, string StateName);

/// <summary>Construction regional supplier/hub (BRD §12).</summary>
public sealed record SupplierResponse(Guid Id, string Code, string Name, Guid DistrictId, string DistrictName, string StateName, string? ContactPhone);
