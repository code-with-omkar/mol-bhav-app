using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Diagnostics.GetApiStatus;

/// <summary>Connectivity probe for the mobile app (exercises routing, versioning, pipeline and envelope end-to-end).</summary>
public sealed record GetApiStatusQuery : IQuery<ApiStatusResponse>;
