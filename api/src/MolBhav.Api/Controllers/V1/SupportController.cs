using System.Net.Mime;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.Contracts.Support;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Support.AddTicketMessage;
using MolBhav.Application.Features.Support.CreateTicket;
using MolBhav.Application.Features.Support.GetMyTickets;
using MolBhav.Application.Features.Support.GetSupportContact;
using MolBhav.Application.Features.Support.GetTicket;
using MolBhav.Application.Features.Support.Models;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// The signed-in user's help requests and the contact channels shown before one is raised. Every ticket read and
/// write is owner-scoped — another user's ticket id behaves as not found. Requires a signed-in user (fallback auth policy).
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/support")]
public sealed class SupportController(ISender sender) : ApiControllerBase(sender)
{
    /// <summary>WhatsApp/phone/email from the <c>Support</c> configuration section; safe to cache for a day.</summary>
    [HttpGet("contact")]
    [ProducesResponseType<ApiResponse<SupportContactResponse>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetContact(CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetSupportContactQuery(), cancellationToken));

    [HttpGet("tickets")]
    [ProducesResponseType<ApiResponse<PagedResult<SupportTicketSummaryResponse>>>(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyTickets(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = PageRequest.DefaultPageSize,
        CancellationToken cancellationToken = default) =>
        PagedEnvelope(await Sender.Send(new GetMyTicketsQuery(page, pageSize), cancellationToken));

    [HttpPost("tickets")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType<ApiResponse<CreatedResponse>>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> CreateTicket([FromBody] CreateTicketRequest request, CancellationToken cancellationToken)
    {
        var command = new CreateTicketCommand(request.Category, request.Subject, request.Message);
        return CreatedEnvelope(await Sender.Send(command, cancellationToken), $"{Request.PathBase}/api/v1/support/tickets");
    }

    /// <summary>The ticket with its full message thread, oldest message first.</summary>
    [HttpGet("tickets/{ticketId:guid}")]
    [ProducesResponseType<ApiResponse<SupportTicketResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> GetTicket(Guid ticketId, CancellationToken cancellationToken) =>
        OkEnvelope(await Sender.Send(new GetTicketQuery(ticketId), cancellationToken));

    /// <summary>Replies to the user's own ticket. A reply to a <c>Resolved</c> ticket reopens it.</summary>
    /// <response code="400">The ticket is closed (<c>SupportTicket.Closed</c>).</response>
    [HttpPost("tickets/{ticketId:guid}/messages")]
    [Consumes(MediaTypeNames.Application.Json)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest, MediaTypeNames.Application.ProblemJson)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound, MediaTypeNames.Application.ProblemJson)]
    public async Task<IActionResult> AddMessage(
        Guid ticketId,
        [FromBody] AddTicketMessageRequest request,
        CancellationToken cancellationToken) =>
        NoContentOrProblem(await Sender.Send(new AddTicketMessageCommand(ticketId, request.Message), cancellationToken));
}
