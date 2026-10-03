using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.GetLoginMethods;

/// <summary>Login screen bootstrap. Anonymous. Tells the app which sign-in options to show.</summary>
public sealed record GetLoginMethodsQuery : IQuery<LoginMethodsResponse>;

public sealed record LoginMethodsResponse(bool Otp, bool Password);
