using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.UnlinkGoogle;

/// <summary>Profile → "Unlink Google". Refused when Google is the only way to sign in (set a password first).</summary>
public sealed record UnlinkGoogleCommand : ICommand;
