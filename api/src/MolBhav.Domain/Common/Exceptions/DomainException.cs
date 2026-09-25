namespace MolBhav.Domain.Common.Exceptions;

/// <summary>
/// Thrown when an aggregate invariant would be violated by a programming error (not by user input —
/// user-input failures are returned as <see cref="Results.Result"/>).
/// </summary>
public sealed class DomainException : Exception
{
    public DomainException(string code, string message)
        : base(message)
    {
        Code = code;
    }

    public DomainException(string code, string message, Exception innerException)
        : base(message, innerException)
    {
        Code = code;
    }

    public string Code { get; }
}
