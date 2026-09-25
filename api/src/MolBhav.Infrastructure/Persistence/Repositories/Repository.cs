using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Infrastructure.Persistence.Repositories;

/// <summary>
/// Base for aggregate repositories. Derived repositories override <see cref="GetByIdAsync"/> to eager-load
/// the aggregate's internal entities (an aggregate is always loaded whole).
/// </summary>
internal abstract class Repository<TAggregate, TId>(MolBhavDbContext dbContext) : IRepository<TAggregate, TId>
    where TAggregate : AggregateRoot<TId>
    where TId : notnull
{
    protected MolBhavDbContext DbContext { get; } = dbContext;

    protected DbSet<TAggregate> Set => DbContext.Set<TAggregate>();

    public virtual async Task<TAggregate?> GetByIdAsync(TId id, CancellationToken cancellationToken = default) =>
        await Set.FindAsync([id], cancellationToken);

    public void Add(TAggregate aggregate)
    {
        ArgumentNullException.ThrowIfNull(aggregate);
        Set.Add(aggregate);
    }

    public void Remove(TAggregate aggregate)
    {
        ArgumentNullException.ThrowIfNull(aggregate);
        Set.Remove(aggregate);
    }
}
