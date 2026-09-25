namespace MolBhav.Api.Contracts.Identity;

/// <summary>Onboarding / edit-profile screen. Full replacement: omitted optional fields are cleared, categories are replaced.</summary>
/// <param name="BusinessType">E.g. "Cloud Kitchen", "General Civil Contractor". Optional.</param>
/// <param name="State">Operating state. Optional.</param>
/// <param name="District">Operating district. Optional.</param>
/// <param name="PreferredLanguage">ISO-639-1: en, hi, mr, gu, ta, te, kn.</param>
/// <param name="Categories">Procurement category codes, e.g. ["agriculture", "construction"].</param>
public sealed record UpdateProfileRequest(
    string? BusinessType,
    string? State,
    string? District,
    string? PreferredLanguage,
    IReadOnlyCollection<string>? Categories);
