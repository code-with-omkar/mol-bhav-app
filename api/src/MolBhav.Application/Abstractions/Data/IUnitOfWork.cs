namespace MolBhav.Application.Abstractions.Data;

/// <summary>
/// Atomic persistence boundary across all repositories touched by one command.
/// Implemented by the EF Core DbContext; commands never call this directly — the
/// <c>UnitOfWorkBehavior</c> wraps every command in <see cref="ExecuteInTransactionAsync{TResult}"/>.
/// </summary>
public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Runs <paramref name="operation"/> inside a database transaction that is retried as a whole on transient failures.
    /// The transaction commits only when <paramref name="shouldCommit"/> returns true for the operation's result;
    /// otherwise it rolls back. Nested calls join the ambient transaction.
    /// </summary>
    Task<TResult> ExecuteInTransactionAsync<TResult>(
        Func<CancellationToken, Task<TResult>> operation,
        Func<TResult, bool> shouldCommit,
        CancellationToken cancellationToken = default);
}
