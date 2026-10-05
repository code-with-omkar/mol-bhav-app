namespace MolBhav.Domain.Weather;

/// <summary>An IMD forecast station. <see cref="Code"/> is the slug the adapter sends to IMD (overridable via <c>Imd:StationCodeMap</c>).</summary>
public sealed record ImdStation(string Code, string Name, string State);
