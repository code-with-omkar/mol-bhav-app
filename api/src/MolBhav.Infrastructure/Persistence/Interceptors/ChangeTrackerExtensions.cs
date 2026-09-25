using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;

namespace MolBhav.Infrastructure.Persistence.Interceptors;

internal static class ChangeTrackerExtensions
{
    /// <summary>True when an owned value (e.g. a Money complex/owned type) changed while the owner row itself did not.</summary>
    public static bool HasChangedOwnedEntities(this EntityEntry entry) =>
        entry.References.Any(reference =>
            reference.TargetEntry is not null
            && reference.TargetEntry.Metadata.IsOwned()
            && reference.TargetEntry.State is EntityState.Added or EntityState.Modified);
}
