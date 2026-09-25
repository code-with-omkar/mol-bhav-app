using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Diagnostics;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Domain.Common.Abstractions;

namespace MolBhav.Infrastructure.Persistence.Interceptors;

/// <summary>Stamps audit columns through EF metadata so domain entities keep private setters.</summary>
internal sealed class AuditableEntityInterceptor(TimeProvider timeProvider, ICurrentUser currentUser) : SaveChangesInterceptor
{
    public override InterceptionResult<int> SavingChanges(DbContextEventData eventData, InterceptionResult<int> result)
    {
        Apply(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        Apply(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private void Apply(DbContext? context)
    {
        if (context is null)
        {
            return;
        }

        var now = timeProvider.GetUtcNow();
        var userId = currentUser.UserId;

        foreach (var entry in context.ChangeTracker.Entries<IAuditableEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    Set(entry, nameof(IAuditableEntity.CreatedAtUtc), now);
                    Set(entry, nameof(IAuditableEntity.CreatedBy), userId);
                    break;

                case EntityState.Modified:
                case EntityState.Unchanged when entry.HasChangedOwnedEntities():
                    Set(entry, nameof(IAuditableEntity.UpdatedAtUtc), now);
                    Set(entry, nameof(IAuditableEntity.UpdatedBy), userId);

                    // Creation stamps are immutable once written.
                    entry.Property(nameof(IAuditableEntity.CreatedAtUtc)).IsModified = false;
                    entry.Property(nameof(IAuditableEntity.CreatedBy)).IsModified = false;
                    break;
            }
        }
    }

    private static void Set(EntityEntry entry, string propertyName, object? value) =>
        entry.Property(propertyName).CurrentValue = value;
}
