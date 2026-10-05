using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.LinkGoogle;

/// <summary>Profile → "Link Google": the signed-in user adds Google as a way to sign in. Returns the linked email.</summary>
public sealed record LinkGoogleCommand(string IdToken) : ICommand<LinkedGoogleResponse>;

public sealed record LinkedGoogleResponse(string? Email);
