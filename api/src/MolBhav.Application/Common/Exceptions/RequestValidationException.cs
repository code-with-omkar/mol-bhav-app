namespace MolBhav.Application.Common.Exceptions;

/// <summary>Raised by the validation pipeline; mapped to HTTP 400 ValidationProblemDetails.</summary>
public sealed class RequestValidationException : Exception
{
    public RequestValidationException(IReadOnlyDictionary<string, string[]> errors)
        : base("One or more validation errors occurred.")
    {
        Errors = errors;
    }

    public IReadOnlyDictionary<string, string[]> Errors { get; }
}
