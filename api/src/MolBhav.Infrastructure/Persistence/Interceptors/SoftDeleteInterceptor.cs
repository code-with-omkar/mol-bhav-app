using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Domain.Common.Abstractions;

namespace MolBhav.Infrastructure.Persistence.Interceptors;

/// <summary>Turns physical deletes of <see cref="ISoftDeletable"/> entities into updates. Registered before auditing.</summary>
internal sealed class SoftDeleteInterceptor(TimeProvider timeProvider, ICurrentUser currentUser) : SaveChangesInterceptor
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

        foreach (var entry in context.ChangeTracker.Entries<ISoftDeletable>().Where(e => e.State == EntityState.Deleted))
        {
            entry.State = EntityState.Modified;
            entry.Property(nameof(ISoftDeletable.IsDeleted)).CurrentValue = true;
            entry.Property(nameof(ISoftDeletable.DeletedAtUtc)).CurrentValue = now;
            entry.Property(nameof(ISoftDeletable.DeletedBy)).CurrentValue = userId;

            // Owned values share the owner's row; cascading their deletion would null those columns.
            foreach (var reference in entry.References)
            {
                if (reference.TargetEntry is { State: EntityState.Deleted } target && target.Metadata.IsOwned())
                {
                    target.State = EntityState.Unchanged;
                }
            }
        }
    }
}
