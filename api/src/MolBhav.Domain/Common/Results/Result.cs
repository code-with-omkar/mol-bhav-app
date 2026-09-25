using System.Diagnostics.CodeAnalysis;

namespace MolBhav.Domain.Common.Results;

/// <summary>
/// Outcome of an operation that can fail for expected reasons. Exceptions are reserved for truly exceptional states.
/// </summary>
public class Result
{
    protected Result(bool isSuccess, Error error)
    {
        ArgumentNullException.ThrowIfNull(error);

        if (isSuccess && error != Error.None)
        {
            throw new InvalidOperationException("A successful result cannot carry an error.");
        }

        if (!isSuccess && error == Error.None)
        {
            throw new InvalidOperationException("A failed result must carry an error.");
        }

        IsSuccess = isSuccess;
        Error = error;
    }

    public bool IsSuccess { get; }

    public bool IsFailure => !IsSuccess;

    public Error Error { get; }

    public static Result Success() => new(true, Error.None);

    public static Result Failure(Error error) => new(false, error);

    public static Result<TValue> Success<TValue>(TValue value) => new(value, true, Error.None);

    public static Result<TValue> Failure<TValue>(Error error) => new(default, false, error);

    /// <summary>Wraps a possibly-null value, failing with <paramref name="errorIfNull"/> when it is null.</summary>
    public static Result<TValue> FromNullable<TValue>(TValue? value, Error errorIfNull)
        where TValue : class =>
        value is null ? Failure<TValue>(errorIfNull) : Success(value);

    public static implicit operator Result(Error error) => Failure(error);
}

public sealed class Result<TValue> : Result
{
    private readonly TValue? _value;

    internal Result(TValue? value, bool isSuccess, Error error)
        : base(isSuccess, error)
    {
        _value = value;
    }

    /// <summary>The value of a successful result. Accessing it on a failure is a programming error.</summary>
    [NotNull]
    public TValue Value => IsSuccess
        ? _value!
        : throw new InvalidOperationException($"Cannot access the value of a failed result ({Error.Code}).");

    public static implicit operator Result<TValue>(TValue value) =>
        value is null ? Failure<TValue>(Error.NullValue) : Success(value);

    public static implicit operator Result<TValue>(Error error) => Failure<TValue>(error);
}
