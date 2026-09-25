using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using MolBhav.Application.Common.Exceptions;
using MolBhav.Domain.Common.Exceptions;

namespace MolBhav.Api.ErrorHandling;

/// <summary>
/// Last line of defence: converts unhandled exceptions to RFC 7807 responses.
/// Internal details (stack traces, SQL) are only exposed in Development.
/// </summary>
internal sealed partial class GlobalExceptionHandler(
    IProblemDetailsService problemDetailsService,
    IHostEnvironment environment,
    ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    private const int ClientClosedRequest = 499;

    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        if (exception is OperationCanceledException && httpContext.RequestAborted.IsCancellationRequested)
        {
            LogRequestAborted(logger, httpContext.Request.Method, httpContext.Request.Path);
            httpContext.Response.StatusCode = ClientClosedRequest;
            return true;
        }

        var problem = exception switch
        {
            RequestValidationException validation => new ValidationProblemDetails(
                validation.Errors.ToDictionary(e => e.Key, e => e.Value, StringComparer.Ordinal))
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "One or more validation errors occurred.",
            },
            ConcurrencyConflictException => Create(StatusCodes.Status409Conflict, "Concurrency conflict.", exception.Message),
            UniqueConstraintViolationException => Create(StatusCodes.Status409Conflict, "Conflict.", exception.Message),
            DomainException domain => Create(StatusCodes.Status422UnprocessableEntity, "Business rule violated.", domain.Message, domain.Code),
            BadHttpRequestException badRequest => Create(badRequest.StatusCode, "Bad request.", null),
            UnauthorizedAccessException => Create(StatusCodes.Status401Unauthorized, "Unauthorized.", null),
            _ => Create(
                StatusCodes.Status500InternalServerError,
                "An unexpected error occurred.",
                environment.IsDevelopment() ? exception.ToString() : null),
        };

        var status = problem.Status ?? StatusCodes.Status500InternalServerError;

        if (status >= StatusCodes.Status500InternalServerError)
        {
            LogUnhandled(logger, httpContext.Request.Method, httpContext.Request.Path, exception);
        }
        else
        {
            var exceptionType = exception.GetType().Name;
            LogHandled(logger, exceptionType, status, httpContext.Request.Method, httpContext.Request.Path);
        }

        httpContext.Response.StatusCode = status;

        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            ProblemDetails = problem,
            Exception = exception,
        });
    }

    private static ProblemDetails Create(int status, string title, string? detail, string? errorCode = null)
    {
        var problem = new ProblemDetails { Status = status, Title = title, Detail = detail };

        if (errorCode is not null)
        {
            problem.Extensions[ProblemDetailsExtensionKeys.ErrorCode] = errorCode;
        }

        return problem;
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Unhandled exception for {Method} {Path}")]
    private static partial void LogUnhandled(ILogger logger, string method, PathString path, Exception exception);

    [LoggerMessage(Level = LogLevel.Information, Message = "{ExceptionType} mapped to {StatusCode} for {Method} {Path}")]
    private static partial void LogHandled(ILogger logger, string exceptionType, int statusCode, string method, PathString path);

    [LoggerMessage(Level = LogLevel.Debug, Message = "Client aborted {Method} {Path}")]
    private static partial void LogRequestAborted(ILogger logger, string method, PathString path);
}
