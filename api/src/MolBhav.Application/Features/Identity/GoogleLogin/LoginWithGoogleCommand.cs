using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Identity.GoogleLogin;

/// <summary>
/// "Continue with Google". Anonymous. A Google account already linked to a MolBhav account logs straight in. A new
/// Google account needs a mobile number (still the account's identity): the first call without one returns
/// <c>Auth.PhoneRequired</c>; the app asks for the number and repeats the call with the same ID token.
/// </summary>
/// <param name="IdToken">The Google ID token from Google Sign-In on the device.</param>
/// <param name="PhoneNumber">Only for a new account: 10-digit Indian mobile.</param>
public sealed record LoginWithGoogleCommand(string IdToken, string? PhoneNumber) : ICommand<LoginSessionResponse>;
