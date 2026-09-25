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
using MolBhav.Application.Features.Identity.Logout;
using MolBhav.Application.Features.Identity.RefreshToken;
using MolBhav.Application.Features.Identity.RequestOtp;
using MolBhav.Application.Features.Identity.VerifyOtp;
using MolBhav.Domain.Identity;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Login screens: mobile number → OTP → session; silent token refresh; logout (BRD §7).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/auth")]
public sealed class AuthController(ISender sender) : ApiControllerBase(sender)
{
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

    private static InvalidOperationException MissingOnSuccess(string field) =>
        new($"Handler reported success but did not populate '{field}'.");
}
