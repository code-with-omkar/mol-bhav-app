using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Admin.GetAdminUser;
using MolBhav.Application.Features.Admin.GetAdminUsers;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Application.Features.Admin.SetUserStatus;
using MolBhav.Domain.Identity;

namespace MolBhav.Api.Controllers.V1;

/// <summary>User management for admins: find users, see one in full, suspend or reinstate an account. Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/users")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminUsersController(ISender sender, ICurrentUser currentUser) : ApiControllerBase(sender)
{
    /// <summary>Users, newest first. <paramref name="search"/> matches part of the phone number or name.</summary>
    [HttpGet]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AdminUserResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetUsers(
        [FromQuery] string? search,
        [FromQuery] UserStatus? status,
        [FromQuery] SubscriptionTier? tier,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetAdminUsersQuery(search, status, tier, page, pageSize), cancellationToken));

    /// <summary>One user in full: profile, categories, latest subscription and support-ticket counts.</summary>
    /// <response code="404">Unknown user (<c>User.NotFound</c>).</response>
    [HttpGet("{userId:guid}")]
    [ProducesResponseType<ApiResponse<AdminUserDetailResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetUser(Guid userId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminUserQuery(userId), cancellationToken));

    /// <summary>
    /// Suspends or reinstates an account. A suspended user cannot sign in or renew a session (an access token already
    /// issued works until it expires). Admins cannot be suspended, and nobody can change their own status.
    /// </summary>
    /// <response code="403">Own account (<c>User.CannotChangeOwnStatus</c>) or an admin (<c>User.AdminCannotBeSuspended</c>).</response>
    /// <response code="404">Unknown user (<c>User.NotFound</c>).</response>
    /// <response code="409">Already in that state (<c>User.AlreadySuspended</c> / <c>User.NotSuspended</c>).</response>
    [HttpPut("{userId:guid}/status")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> SetStatus(Guid userId, [FromBody] SetUserStatusRequest request, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new SetUserStatusCommand(userId, request.Action, currentUser.GetRequiredUserId()), cancellationToken));
}

/// <summary>Body of <c>PUT /admin/users/{id}/status</c>: <c>"Suspend"</c> or <c>"Reinstate"</c>.</summary>
public sealed record SetUserStatusRequest(UserStatusAction Action);
