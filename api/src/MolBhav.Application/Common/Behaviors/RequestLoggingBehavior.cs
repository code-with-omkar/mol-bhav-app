using System.Diagnostics;
using MediatR;
using Microsoft.Extensions.Logging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Common.Behaviors;

/// <summary>
/// Outermost behaviour: logs every request with elapsed time, flags anything slower than the
/// 500 ms dashboard NFR, and records expected failures (Result.Failure) at warning level.
/// Request payloads are not logged (they may contain phone numbers/OTP).
/// </summary>
internal sealed partial class RequestLoggingBehavior<TRequest, TResponse>(ILogger<RequestLoggingBehavior<TRequest, TResponse>> logger)
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private const long SlowRequestThresholdMs = 500;

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        var started = Stopwatch.GetTimestamp();

        var response = await next(cancellationToken);

        var elapsedMs = (long)Stopwatch.GetElapsedTime(started).TotalMilliseconds;

        if (response is Result { IsFailure: true } failed)
        {
            LogFailure(logger, requestName, failed.Error.Code, elapsedMs);
        }
        else if (elapsedMs > SlowRequestThresholdMs)
        {
            LogSlow(logger, requestName, elapsedMs);
        }
        else
        {
            LogCompleted(logger, requestName, elapsedMs);
        }

        return response;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "{RequestName} completed in {ElapsedMs} ms")]
    private static partial void LogCompleted(ILogger logger, string requestName, long elapsedMs);

    [LoggerMessage(Level = LogLevel.Warning, Message = "{RequestName} completed in {ElapsedMs} ms (slow)")]
    private static partial void LogSlow(ILogger logger, string requestName, long elapsedMs);

    [LoggerMessage(Level = LogLevel.Warning, Message = "{RequestName} failed with {ErrorCode} in {ElapsedMs} ms")]
    private static partial void LogFailure(ILogger logger, string requestName, string errorCode, long elapsedMs);
}
