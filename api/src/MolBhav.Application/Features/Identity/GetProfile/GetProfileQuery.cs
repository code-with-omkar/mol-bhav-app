using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.GetProfile;

/// <summary>Profile screen. Operates on the current authenticated user — no id parameter.</summary>
public sealed record GetProfileQuery : IQuery<UserProfileResponse>;
