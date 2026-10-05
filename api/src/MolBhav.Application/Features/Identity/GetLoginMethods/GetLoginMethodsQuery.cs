using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.GetLoginMethods;

/// <summary>Login screen bootstrap. Anonymous. Tells the app which sign-in options to show.</summary>
public sealed record GetLoginMethodsQuery : IQuery<LoginMethodsResponse>;

/// <param name="Otp">Mobile number + SMS code.</param>
/// <param name="Password">Mobile number + password.</param>
/// <param name="Google">"Continue with Google".</param>
/// <param name="GoogleClientId">Google OAuth web client id for the app's Google Sign-In; null when Google is off.</param>
public sealed record LoginMethodsResponse(bool Otp, bool Password, bool Google, string? GoogleClientId);
