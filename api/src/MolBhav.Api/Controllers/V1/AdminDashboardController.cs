using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.Admin.GetAdminDashboard;
using MolBhav.Application.Features.Admin.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The admin app's landing screen. Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/dashboard")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminDashboardController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Headline numbers: users, sponsored-ad delivery and rewarded views, price-feed health, open support tickets.</summary>
    [HttpGet("overview")]
    [ProducesResponseType<ApiResponse<AdminDashboardResponse>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOverview(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminDashboardQuery(), cancellationToken));
}
