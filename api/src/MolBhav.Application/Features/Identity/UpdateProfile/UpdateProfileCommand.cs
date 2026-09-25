using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.UpdateProfile;

/// <summary>Onboarding / edit-profile screen (BRD §7). Requires authentication.</summary>
public sealed record UpdateProfileCommand(
    string? BusinessType,
    string? State,
    string? District,
    string PreferredLanguage,
    IReadOnlyCollection<string> Categories) : ICommand<UpdateProfileResponse>;
