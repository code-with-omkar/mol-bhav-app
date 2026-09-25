namespace MolBhav.Application.Common.Exceptions;

/// <summary>
/// A unique index rejected the write (race between two identical requests). Mapped to HTTP 409.
/// Handlers should still pre-check uniqueness to return a friendly <c>Result</c> in the common case.
/// </summary>
public sealed class UniqueConstraintViolationException : Exception
{
    public UniqueConstraintViolationException(string? constraintName, Exception innerException)
        : base("The record conflicts with an existing record.", innerException)
    {
        ConstraintName = constraintName;
    }

    public string? ConstraintName { get; }
}
