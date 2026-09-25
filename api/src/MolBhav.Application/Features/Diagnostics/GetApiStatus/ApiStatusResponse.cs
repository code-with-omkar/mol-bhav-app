namespace MolBhav.Application.Features.Diagnostics.GetApiStatus;

public sealed record ApiStatusResponse(string Service, string Version, string Language, DateTimeOffset ServerTimeUtc);
