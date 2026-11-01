namespace MolBhav.Application.Features.AppVersions.Models;

/// <param name="MinimumVersion">Oldest version allowed to run, as <c>major.minor.patch</c>; null when there is no minimum.</param>
/// <param name="UpdateUrl">Where to update from (a store page); null when none is set.</param>
public sealed record AppVersionPolicyResponse(string? MinimumVersion, string? UpdateUrl);

/// <param name="MinimumVersion">Oldest version allowed to run (<c>1.2.0</c>); empty for no minimum.</param>
/// <param name="UpdateUrl">Where to update from; empty for none.</param>
public sealed record SetAppVersionPolicyRequest(string? MinimumVersion, string? UpdateUrl);
