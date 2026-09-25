namespace MolBhav.Domain.Common.Abstractions;

/// <summary>
/// Entities whose deletion is logical. The persistence layer converts a physical delete into an update
/// and applies a global query filter on <see cref="IsDeleted"/>.
/// </summary>
public interface ISoftDeletable
{
    bool IsDeleted { get; }

    DateTimeOffset? DeletedAtUtc { get; }

    Guid? DeletedBy { get; }
}
