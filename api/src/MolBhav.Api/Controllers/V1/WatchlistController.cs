using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Watchlist;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Watchlist.AddToWatchlist;
using MolBhav.Application.Features.Watchlist.GetWatchlist;
using MolBhav.Application.Features.Watchlist.Models;
using MolBhav.Application.Features.Watchlist.RemoveFromWatchlist;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The signed-in user's smart commodity watchlist (BRD §7/§10). Requires a signed-in user (fallback auth policy).</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/watchlist")]
public sealed class WatchlistController(ISender sender) : ApiControllerBase(sender)
{
    [HttpGet]
    [ProducesResponseType<ApiResponse<IReadOnlyList<WatchlistItemResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetWatchlist(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetWatchlistQuery(), cancellationToken));

    /// <response code="404">Unknown product, or the variant does not belong to it (<c>Product.NotFound</c>, <c>ProductVariant.NotFound</c>).</response>
    /// <response code="409">Already on the watchlist (<c>WatchlistItem.AlreadyWatched</c>).</response>
    [HttpPost]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> AddToWatchlist([FromBody] AddToWatchlistRequest request, CancellationToken cancellationToken)
    {
        var command = new AddToWatchlistCommand(request.ProductId ?? Guid.Empty, request.VariantId);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/watchlist");
    }

    [HttpDelete("{watchlistItemId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> RemoveFromWatchlist(Guid watchlistItemId, CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new RemoveFromWatchlistCommand(watchlistItemId), cancellationToken));
}
