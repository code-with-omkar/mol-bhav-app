using System.Net.Mime;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Api.Contracts;
using MolBhav.Api.ErrorHandling;
using MolBhav.Application.Common.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Api.Controllers;

/// <summary>
/// Thin controllers: bind → send to MediatR → map <see cref="Result"/> to HTTP. No business logic here.
/// Each controller declares its own <c>[ApiVersion]</c> and <c>[Route("api/v{version:apiVersion}/…")]</c>.
/// </summary>
[ApiController]
[Produces(MediaTypeNames.Application.Json)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status401Unauthorized, MediaTypeNames.Application.ProblemJson)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status429TooManyRequests, MediaTypeNames.Application.ProblemJson)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status500InternalServerError, MediaTypeNames.Application.ProblemJson)]
public abstract class ApiControllerBase(ISender sender) : ControllerBase
{
    protected ISender Sender { get; } = sender;

    protected IActionResult OkEnvelope<T>(Result<T> result, string? message = null) =>
        result.IsSuccess ? Ok(ApiResponse.Ok(result.Value, message)) : ToProblem(result.Error);

    protected IActionResult CreatedEnvelope<T>(Result<T> result, string actionName, Func<T, object> routeValues) =>
        result.IsSuccess
            ? CreatedAtAction(actionName, routeValues(result.Value), ApiResponse.Ok(result.Value))
            : ToProblem(result.Error);

    protected IActionResult PagedEnvelope<T>(Result<PagedResult<T>> result, string? message = null) =>
        result.IsSuccess ? Ok(ApiResponse.Paged(result.Value, message)) : ToProblem(result.Error);

    /// <summary>201 with a Location for resources that are read back through a collection (no single-item GET).</summary>
    protected IActionResult CreatedEnvelope<T>(Result<T> result, string location) =>
        result.IsSuccess ? Created(location, ApiResponse.Ok(result.Value)) : ToProblem(result.Error);

    protected IActionResult NoContentOrProblem(Result result) =>
        result.IsSuccess ? NoContent() : ToProblem(result.Error);

    protected ObjectResult ToProblem(Error error)
    {
        ArgumentNullException.ThrowIfNull(error);

        var status = error.Type.ToStatusCode();
        var problem = ProblemDetailsFactory.CreateProblemDetails(HttpContext, statusCode: status, detail: error.Description);
        problem.Extensions[ProblemDetailsExtensionKeys.ErrorCode] = error.Code;

        return new ObjectResult(problem)
        {
            StatusCode = status,
            ContentTypes = { MediaTypeNames.Application.ProblemJson },
        };
    }
}
