using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;

namespace MolBhav.Infrastructure.Persistence.Interceptors;

internal static class ChangeTrackerExtensions
{
    /// <summary>
    /// Owner entities (outermost non-owned) whose owned data changed: owned references and owned collections,
    /// including items added to or removed from a collection (e.g. a category's translations, a user's categories).
    /// Such an owner can itself be <see cref="EntityState.Unchanged"/> — only its owned rows changed — yet it has been
    /// modified from the domain's point of view, so it must still be audited.
    /// </summary>
    public static HashSet<object> OwnersWithChangedOwnedData(this ChangeTracker changeTracker)
    {
        var owners = new HashSet<object>(ReferenceEqualityComparer.Instance);
        var entries = changeTracker.Entries().ToList();

        foreach (var owned in entries.Where(e => e.Metadata.IsOwned() && e.State is EntityState.Added or EntityState.Modified or EntityState.Deleted))
        {
            var owner = FindOwner(entries, owned);

            // Nested owned types: climb to the non-owned entity that is actually audited.
            while (owner is not null && owner.Metadata.IsOwned())
            {
                owner = FindOwner(entries, owner);
            }

            if (owner is not null)
            {
                owners.Add(owner.Entity);
            }
        }

        return owners;
    }

    private static EntityEntry? FindOwner(List<EntityEntry> entries, EntityEntry owned)
    {
        var ownership = owned.Metadata.FindOwnership();
        if (ownership is null)
        {
            return null;
        }

        // A removed item keeps its FK only in the original values.
        var foreignKey = ownership.Properties
            .Select(p => owned.State == EntityState.Deleted ? owned.Property(p.Name).OriginalValue : owned.Property(p.Name).CurrentValue)
            .ToArray();

        return entries.FirstOrDefault(candidate =>
            candidate.Metadata == ownership.PrincipalEntityType
            && ownership.PrincipalKey.Properties
                .Select(k => candidate.Property(k.Name).CurrentValue)
                .SequenceEqual(foreignKey));
    }
}
