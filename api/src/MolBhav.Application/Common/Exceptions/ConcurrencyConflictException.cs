namespace MolBhav.Application.Common.Exceptions;

/// <summary>Optimistic-concurrency failure (row changed since it was read). Mapped to HTTP 409.</summary>
public sealed class ConcurrencyConflictException : Exception
{
    public ConcurrencyConflictException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}
