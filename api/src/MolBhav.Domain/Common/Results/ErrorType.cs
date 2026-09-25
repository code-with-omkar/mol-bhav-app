namespace MolBhav.Domain.Common.Results;

/// <summary>Classifies an expected failure; the API layer maps each value to an HTTP status code.</summary>
public enum ErrorType
{
    Failure = 0,
    Validation = 1,
    NotFound = 2,
    Conflict = 3,
    Unauthorized = 4,
    Forbidden = 5,
    BusinessRule = 6,
}
