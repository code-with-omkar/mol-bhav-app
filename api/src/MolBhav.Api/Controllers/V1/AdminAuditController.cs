using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Audit.GetAuditEntries;
using MolBhav.Application.Features.Audit.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The record of what admins changed: who did what, to which record, and when. Read-only. Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/audit")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminAuditController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Entries newest first. <paramref name="action"/> (an exact code such as <c>User.Suspend</c>) narrows the list.</summary>
    [HttpGet]
    [ProducesResponseType<ApiResponse<IReadOnlyList<AuditEntryResponse>>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetEntries(
        [FromQuery] string? action,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize) =>
        PagedEnvelope(await Sender.Send(new GetAuditEntriesQuery(action, page, pageSize), cancellationToken));
}
