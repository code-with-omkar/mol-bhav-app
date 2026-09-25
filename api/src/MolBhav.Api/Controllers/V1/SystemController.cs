using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Application.Features.Diagnostics.GetApiStatus;

namespace MolBhav.Api.Controllers.V1;

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/system")]
public sealed class SystemController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Connectivity and language-negotiation check for the mobile app.</summary>
    [HttpGet("status")]
    [AllowAnonymous]
    [ProducesResponseType<ApiResponse<ApiStatusResponse>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetStatus(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetApiStatusQuery(), cancellationToken));
}
