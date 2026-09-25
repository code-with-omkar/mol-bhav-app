namespace MolBhav.Domain.Common.Primitives;

/// <summary>Identity-based equality for all entities.</summary>
public abstract class Entity<TId> : IEquatable<Entity<TId>>
    where TId : notnull
{
    protected Entity(TId id)
    {
        if (id is Guid guid && guid == Guid.Empty)
        {
            throw new ArgumentException("Entity identifier cannot be an empty GUID.", nameof(id));
        }

        Id = id;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    protected Entity()
    {
        Id = default!;
    }

    public TId Id { get; private init; }

    public static bool operator ==(Entity<TId>? left, Entity<TId>? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(Entity<TId>? left, Entity<TId>? right) => !(left == right);

    public bool Equals(Entity<TId>? other)
    {
        if (other is null)
        {
            return false;
        }

        if (ReferenceEquals(this, other))
        {
            return true;
        }

        return other.GetType() == GetType() && EqualityComparer<TId>.Default.Equals(Id, other.Id);
    }

    public override bool Equals(object? obj) => obj is Entity<TId> entity && Equals(entity);

    public override int GetHashCode() => HashCode.Combine(GetType(), Id);
}
