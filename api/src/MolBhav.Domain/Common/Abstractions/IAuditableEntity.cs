namespace MolBhav.Domain.Common.Abstractions;

/// <summary>
/// Audit columns stamped by the persistence layer (never by domain code).
/// Implement with private setters; the SaveChanges interceptor writes them through EF metadata.
/// <c>CreatedBy</c>/<c>UpdatedBy</c> intentionally carry no FK to users: audit history must survive user deletion
/// and must not couple every schema to the identity schema.
/// </summary>
public interface IAuditableEntity
{
    DateTimeOffset CreatedAtUtc { get; }

    Guid? CreatedBy { get; }

    DateTimeOffset? UpdatedAtUtc { get; }

    Guid? UpdatedBy { get; }
}
