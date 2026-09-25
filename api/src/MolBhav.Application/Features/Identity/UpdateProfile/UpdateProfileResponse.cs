namespace MolBhav.Application.Features.Identity.UpdateProfile;

public sealed record UpdateProfileResponse(Guid UserId, string PreferredLanguage, IReadOnlyList<string> Categories);
