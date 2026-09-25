namespace MolBhav.Api.ErrorHandling;

internal static class ProblemDetailsExtensionKeys
{
    /// <summary>Stable machine-readable code (e.g. <c>PhoneNumber.Invalid</c>) the app localises.</summary>
    public const string ErrorCode = "errorCode";

    public const string TraceId = "traceId";
}
