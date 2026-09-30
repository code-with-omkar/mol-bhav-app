using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Application.Features.Localization.GetLocalizedTexts;

namespace MolBhav.Api.Controllers.V1;

/// <summary>Data-driven terminology for the mobile app (BRD §18: "database/config-driven localized metadata"), resolved for <c>Accept-Language</c>.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/localization")]
public sealed class LocalizationController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>Every key (or one namespace, e.g. <c>?keyPrefix=alerts.</c>) resolved to text in the request's language, falling back to English.</summary>
    [HttpGet("texts")]
    [ProducesResponseType<ApiResponse<IReadOnlyDictionary<string, string>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTexts([FromQuery] string? keyPrefix, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetLocalizedTextsQuery(keyPrefix), cancellationToken));
}
