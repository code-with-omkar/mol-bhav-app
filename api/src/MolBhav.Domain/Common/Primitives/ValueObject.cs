namespace MolBhav.Domain.Common.Primitives;

/// <summary>
/// Structural equality for value objects that cannot be expressed as a <c>record</c>
/// (e.g. when normalisation logic must run in a private constructor). Prefer sealed records where possible.
/// </summary>
public abstract class ValueObject : IEquatable<ValueObject>
{
    public static bool operator ==(ValueObject? left, ValueObject? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(ValueObject? left, ValueObject? right) => !(left == right);

    public bool Equals(ValueObject? other) =>
        other is not null
        && other.GetType() == GetType()
        && GetEqualityComponents().SequenceEqual(other.GetEqualityComponents());

    public override bool Equals(object? obj) => obj is ValueObject valueObject && Equals(valueObject);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        foreach (var component in GetEqualityComponents())
        {
            hash.Add(component);
        }

        return hash.ToHashCode();
    }

    protected abstract IEnumerable<object?> GetEqualityComponents();
}
