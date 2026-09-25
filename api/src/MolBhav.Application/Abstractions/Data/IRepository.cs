using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Application.Abstractions.Data;

/// <summary>
/// Write-side repository for an aggregate root. Deliberately minimal: queries for screens/reports go through
/// dedicated read services (Dapper) rather than growing this interface.
/// Changes are persisted by <see cref="IUnitOfWork"/>, never by the repository itself.
/// </summary>
public interface IRepository<TAggregate, in TId>
    where TAggregate : AggregateRoot<TId>
    where TId : notnull
{
    Task<TAggregate?> GetByIdAsync(TId id, CancellationToken cancellationToken = default);

    void Add(TAggregate aggregate);

    void Remove(TAggregate aggregate);
}
