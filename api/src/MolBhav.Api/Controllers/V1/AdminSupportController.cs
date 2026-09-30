using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Support;
using MolBhav.Api.Setup;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Support.Admin.AddAdminTicketMessage;
using MolBhav.Application.Features.Support.Admin.GetAdminTicket;
using MolBhav.Application.Features.Support.Admin.GetAdminTickets;
using MolBhav.Application.Features.Support.Admin.UpdateTicketStatus;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Support;

namespace MolBhav.Api.Controllers.V1;

/// <summary>The support queue: any user's ticket, replies, and the only route that sets status. Admin role only.</summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/admin/support/tickets")]
[Authorize(Policy = AuthorizationPolicies.Admin)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden, MediaTypeNames.Application.ProblemJson)]
public sealed class AdminSupportController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary><paramref name="search"/> matches the subject, case-insensitively.</summary>
    [HttpGet]
    [ProducesResponseType<ApiResponse<PagedResult<AdminSupportTicketResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTickets(
        [FromQuery] SupportTicketStatus? status,
        [FromQuery] SupportTicketCategory? category,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetAdminTicketsQuery(status, category, search, page, pageSize), cancellationToken));

    [HttpGet("{ticketId:guid}")]
    [ProducesResponseType<ApiResponse<SupportTicketResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetTicket(Guid ticketId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetAdminTicketQuery(ticketId), cancellationToken));

    /// <summary>Support's reply. Moves an <c>Open</c> ticket to <c>InProgress</c> and notifies the owner.</summary>
    /// <response code="400">The ticket is closed (<c>SupportTicket.Closed</c>).</response>
    [HttpPost("{ticketId:guid}/messages")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> AddMessage(
        Guid ticketId,
        [FromBody] AddTicketMessageRequest request,
        CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new AddAdminTicketMessageCommand(ticketId, request.Message), cancellationToken));

    /// <response code="400">The ticket is already closed (<c>SupportTicket.Closed</c>) — that state is terminal.</response>
    [HttpPut("{ticketId:guid}/status")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> UpdateStatus(
        Guid ticketId,
        [FromBody] UpdateTicketStatusRequest request,
        CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new UpdateTicketStatusCommand(ticketId, request.Status), cancellationToken));
}
