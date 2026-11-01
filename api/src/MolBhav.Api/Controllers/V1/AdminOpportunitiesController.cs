using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Setup;
using MolBhav.Application.Features.Alerting.Opportunities.ScanMarketOpportunities;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Runs the market-opportunity scan on demand (it also runs daily on its own). Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/opportunities")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminOpportunitiesController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Scans every watchlist now. Users already given an opportunity today for a product are skipped.</summary>
    [HttpPost("scan")]
    [ProducesResponseType<ApiResponse<OpportunityScanResult>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> Scan(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new ScanMarketOpportunitiesCommand(), cancellationToken));
}
