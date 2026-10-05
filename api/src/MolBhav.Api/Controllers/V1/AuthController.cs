using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Identity;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.Identity;
using MolBhav.Application.Features.Identity.GetLoginMethods;
using MolBhav.Application.Features.Identity.GoogleLogin;
using MolBhav.Application.Features.Identity.LinkGoogle;
using MolBhav.Application.Features.Identity.Logout;
using MolBhav.Application.Features.Identity.PasswordLogin;
using MolBhav.Application.Features.Identity.RefreshToken;
using MolBhav.Application.Features.Identity.RegisterWithPassword;
using MolBhav.Application.Features.Identity.RequestOtp;
using MolBhav.Application.Features.Identity.UnlinkGoogle;
using MolBhav.Application.Features.Identity.VerifyOtp;
using MolBhav.Domain.Identity;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Login screens: mobile number + password, or mobile number → OTP (each switchable via <c>Authentication:LoginMethods</c>);
/// silent token refresh; logout (BRD §7).
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/auth")]
public sealed class AuthController(ISender sender, TimeProvider timeProvider) : ApiControllerBase(sender)
{
    /// <summary>Which sign-in methods are enabled. The app calls this before rendering the login screen.</summary>
    /// <response code="200">Enabled methods.</response>
    [HttpGet("methods")]
    [AllowAnonymous]
    [ProducesResponseType<ApiResponse<LoginMethodsDto>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLoginMethods(CancellationToken cancellationToken)
    {
        var result = await Sender.Send(new GetLoginMethodsQuery(), cancellationToken);

        return result.IsSuccess
            ? Ok(ApiResponse.Ok(new LoginMethodsDto(result.Value.Otp, result.Value.Password, result.Value.Google, result.Value.GoogleClientId)))
            : ToProblem(result.Error);
    }

    /// <summary>Creates an account with a password and logs it in. No SMS is sent; the number is not verified on this path.</summary>
    /// <response code="200">Registered and logged in. <c>isOnboarded = false</c> → show the onboarding screen next.</response>
    /// <response code="400">Invalid mobile number or a password that breaks the policy (<c>Password.TooWeak</c>).</response>
    /// <response code="403">Password login is disabled (<c>Auth.MethodDisabled</c>).</response>
    /// <response code="409">The number already has an account (<c>Auth.AccountExists</c>) — log in instead.</response>
    [HttpPost("password/register")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitPolicies.PasswordLogin)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<LoginResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RegisterWithPassword([FromBody] PasswordCredentialsRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(
            new RegisterWithPasswordCommand(request.PhoneNumber ?? string.Empty, request.Password ?? string.Empty),
            cancellationToken);

        return result.IsSuccess ? Ok(ApiResponse.Ok(ToLoginResponse(result.Value))) : ToProblem(result.Error);
    }

    /// <summary>Logs in with mobile number + password.</summary>
    /// <response code="200">Logged in.</response>
    /// <response code="400">Wrong number or password (<c>Auth.InvalidCredentials</c> — never says which) or invalid input.</response>
    /// <response code="403">Password login is disabled (<c>Auth.MethodDisabled</c>) or the account is suspended (<c>User.Suspended</c>).</response>
    /// <response code="422">Temporarily locked after too many wrong passwords (<c>Auth.LockedOut</c>).</response>
    [HttpPost("password/login")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitPolicies.PasswordLogin)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<LoginResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status422UnprocessableEntity, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> LoginWithPassword([FromBody] PasswordCredentialsRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(
            new LoginWithPasswordCommand(request.PhoneNumber ?? string.Empty, request.Password ?? string.Empty),
            cancellationToken);

        if (result.IsFailure)
        {
            return ToProblem(result.Error);
        }

        var login = result.Value;
        return login.Outcome switch
        {
            PasswordLoginOutcome.Succeeded => Ok(ApiResponse.Ok(
                ToLoginResponse(login.Session ?? throw MissingOnSuccess(nameof(login.Session))))),
            PasswordLoginOutcome.LockedOut => ToProblem(IdentityErrors.LockedOut(login.LockedUntilUtc, timeProvider.GetUtcNow())),
            _ => ToProblem(IdentityErrors.InvalidCredentials),
        };
    }

    /// <summary>"Continue with Google". A linked Google account logs in; a new one needs <c>phoneNumber</c> on a second call.</summary>
    /// <response code="200">Logged in (or registered — <c>isNewUser</c>).</response>
    /// <response code="400">The Google token did not verify (<c>Auth.GoogleTokenInvalid</c>) or invalid mobile number.</response>
    /// <response code="403">Google sign-in is off (<c>Auth.MethodDisabled</c>) or the account is suspended.</response>
    /// <response code="409">The mobile number already has an account (<c>Auth.AccountExists</c>) — log in with password and link Google.</response>
    /// <response code="422">New Google account: send the mobile number too (<c>Auth.PhoneRequired</c>).</response>
    [HttpPost("google")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitPolicies.PasswordLogin)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<LoginResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status422UnprocessableEntity, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> LoginWithGoogle([FromBody] GoogleLoginRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(
            new LoginWithGoogleCommand(request.IdToken ?? string.Empty, request.PhoneNumber),
            cancellationToken);

        return result.IsSuccess ? Ok(ApiResponse.Ok(ToLoginResponse(result.Value))) : ToProblem(result.Error);
    }

    /// <summary>Links a Google account to the signed-in user, so they can also sign in with Google.</summary>
    /// <response code="200">Linked.</response>
    /// <response code="409">That Google account belongs to another user, or a different one is already linked.</response>
    [HttpPost("google/link")]
    [Authorize]
    [EnableRateLimiting(RateLimitPolicies.PasswordLogin)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<LinkedGoogleDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> LinkGoogle([FromBody] GoogleLinkRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(new LinkGoogleCommand(request.IdToken ?? string.Empty), cancellationToken);
        return result.IsSuccess ? Ok(ApiResponse.Ok(new LinkedGoogleDto(result.Value.Email))) : ToProblem(result.Error);
    }

    /// <summary>Removes the Google sign-in from the signed-in user.</summary>
    /// <response code="204">Unlinked (or nothing was linked).</response>
    /// <response code="422">Google is the only way to sign in — set a password first (<c>User.LastSignInMethod</c>).</response>
    [HttpDelete("google/link")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status422UnprocessableEntity, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UnlinkGoogle(CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new UnlinkGoogleCommand(), cancellationToken));

    /// <summary>Sends a 6-digit login code to the mobile number. Creates no account.</summary>
    /// <response code="200">Code sent; valid until <c>expiresAtUtc</c>.</response>
    /// <response code="400">Invalid mobile number (<c>PhoneNumber.Invalid</c>).</response>
    /// <response code="422">A code was sent less than a minute ago (<c>Otp.ResendTooSoon</c>).</response>
    [HttpPost("otp/request")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitPolicies.Otp)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<OtpSentResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status422UnprocessableEntity, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RequestOtp([FromBody] RequestOtpRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(new RequestOtpCommand(request.PhoneNumber ?? string.Empty), cancellationToken);

        return result.IsSuccess
            ? Ok(ApiResponse.Ok(new OtpSentResponse(result.Value.ExpiresAtUtc, result.Value.ResendCooldownSeconds)))
            : ToProblem(result.Error);
    }

    /// <summary>Verifies the code. The first successful verification for a number registers the account.</summary>
    /// <response code="200">Logged in. <c>isOnboarded = false</c> → show the onboarding screen next.</response>
    /// <response code="400">Wrong code (<c>Otp.Incorrect</c>), no code requested (<c>Otp.ChallengeNotFound</c>) or invalid input.</response>
    /// <response code="403">Account suspended (<c>User.Suspended</c>).</response>
    /// <response code="422">Code expired, already used, or too many wrong attempts — request a new code.</response>
    [HttpPost("otp/verify")]
    [AllowAnonymous]
    [EnableRateLimiting(RateLimitPolicies.OtpVerify)]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<LoginResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status422UnprocessableEntity, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(
            new VerifyOtpCommand(request.PhoneNumber ?? string.Empty, request.Code ?? string.Empty),
            cancellationToken);

        if (result.IsFailure)
        {
            return ToProblem(result.Error);
        }

        var verification = result.Value;
        if (verification.Outcome != OtpVerificationOutcome.Verified)
        {
            return ToProblem(IdentityErrors.ForOtpOutcome(verification.Outcome));
        }

        var session = new SessionResponse(
            verification.UserId ?? throw MissingOnSuccess(nameof(verification.UserId)),
            verification.AccessToken ?? throw MissingOnSuccess(nameof(verification.AccessToken)),
            verification.AccessTokenExpiresAtUtc ?? throw MissingOnSuccess(nameof(verification.AccessTokenExpiresAtUtc)),
            verification.RefreshToken ?? throw MissingOnSuccess(nameof(verification.RefreshToken)),
            verification.RefreshTokenExpiresAtUtc ?? throw MissingOnSuccess(nameof(verification.RefreshTokenExpiresAtUtc)));

        return Ok(ApiResponse.Ok(new LoginResponse(session, verification.IsNewUser, verification.IsOnboarded)));
    }

    /// <summary>Exchanges a refresh token for a new session. The presented refresh token is consumed (single use).</summary>
    /// <response code="200">New access + refresh token — replace both in secure storage.</response>
    /// <response code="401">Refresh token invalid, expired or revoked — clear tokens and return to login.</response>
    /// <response code="409">Token was just rotated by a parallel refresh (<c>RefreshToken.Superseded</c>) — retry with the stored token.</response>
    [HttpPost("token/refresh")]
    [AllowAnonymous]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<SessionResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request, CancellationToken cancellationToken)
    {
        var result = await Sender.Send(new RefreshTokenCommand(request.RefreshToken ?? string.Empty), cancellationToken);

        if (result.IsFailure)
        {
            return ToProblem(result.Error);
        }

        var refresh = result.Value;
        if (refresh.Outcome != RefreshTokenOutcome.Rotated)
        {
            return ToProblem(IdentityErrors.ForRefreshOutcome(refresh.Outcome));
        }

        var session = new SessionResponse(
            refresh.UserId ?? throw MissingOnSuccess(nameof(refresh.UserId)),
            refresh.AccessToken ?? throw MissingOnSuccess(nameof(refresh.AccessToken)),
            refresh.AccessTokenExpiresAtUtc ?? throw MissingOnSuccess(nameof(refresh.AccessTokenExpiresAtUtc)),
            refresh.RefreshToken ?? throw MissingOnSuccess(nameof(refresh.RefreshToken)),
            refresh.RefreshTokenExpiresAtUtc ?? throw MissingOnSuccess(nameof(refresh.RefreshTokenExpiresAtUtc)));

        return Ok(ApiResponse.Ok(session));
    }

    /// <summary>Revokes this device's refresh token. Idempotent. The (short-lived) access token simply expires.</summary>
    /// <response code="204">Logged out.</response>
    [HttpPost("logout")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new LogoutCommand(request.RefreshToken ?? string.Empty), cancellationToken));

    private static LoginResponse ToLoginResponse(LoginSessionResponse login) =>
        new(
            new SessionResponse(
                login.UserId,
                login.AccessToken,
                login.AccessTokenExpiresAtUtc,
                login.RefreshToken,
                login.RefreshTokenExpiresAtUtc),
            login.IsNewUser,
            login.IsOnboarded);

    private static InvalidOperationException MissingOnSuccess(string field) =>
        new($"Handler reported success but did not populate '{field}'.");
}
