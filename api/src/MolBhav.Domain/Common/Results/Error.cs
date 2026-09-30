namespace MolBhav.Domain.Common.Results;

/// <summary>
/// An expected, recoverable failure. <see cref="Code"/> is stable and machine-readable
/// (e.g. <c>Watchlist.ItemAlreadyExists</c>) so the mobile app can localise messages client-side.
/// </summary>
public sealed record Error
{
    public static readonly Error None = new(string.Empty, string.Empty, ErrorType.Failure);

    public static readonly Error NullValue = new("General.NullValue", "A required value was not provided.", ErrorType.Validation);

    private Error(string code, string description, ErrorType type)
    {
        Code = code;
        Description = description;
        Type = type;
    }

    public string Code { get; }

    public string Description { get; }

    public ErrorType Type { get; }

    public static Error Failure(string code, string description) => Create(code, description, ErrorType.Failure);

    public static Error Validation(string code, string description) => Create(code, description, ErrorType.Validation);

    public static Error NotFound(string code, string description) => Create(code, description, ErrorType.NotFound);

    public static Error Conflict(string code, string description) => Create(code, description, ErrorType.Conflict);

    public static Error Unauthorized(string code, string description) => Create(code, description, ErrorType.Unauthorized);

    public static Error Forbidden(string code, string description) => Create(code, description, ErrorType.Forbidden);

    public static Error BusinessRule(string code, string description) => Create(code, description, ErrorType.BusinessRule);

    public static Error Unavailable(string code, string description) => Create(code, description, ErrorType.Unavailable);

    private static Error Create(string code, string description, ErrorType type)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(code);
        ArgumentException.ThrowIfNullOrWhiteSpace(description);
        return new Error(code, description, type);
    }
}
