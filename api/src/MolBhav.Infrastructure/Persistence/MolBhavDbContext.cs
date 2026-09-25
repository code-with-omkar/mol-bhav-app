using System.Data;
using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Common.Exceptions;
using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.SharedKernel;
using MolBhav.Infrastructure.Persistence.Conventions;
using Npgsql;

namespace MolBhav.Infrastructure.Persistence;

/// <summary>
/// Single write model for the modular monolith. Modules are separated by PostgreSQL schema (see <see cref="Schemas"/>)
/// and by their own <c>IEntityTypeConfiguration</c> classes; no DbSet properties are exposed — repositories use <c>Set&lt;T&gt;()</c>.
/// </summary>
public sealed class MolBhavDbContext(DbContextOptions<MolBhavDbContext> options) : DbContext(options), IUnitOfWork
{
    public async Task<TResult> ExecuteInTransactionAsync<TResult>(
        Func<CancellationToken, Task<TResult>> operation,
        Func<TResult, bool> shouldCommit,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(operation);
        ArgumentNullException.ThrowIfNull(shouldCommit);

        // Nested command (e.g. a domain-event handler sending a command): join the ambient transaction.
        if (Database.CurrentTransaction is not null)
        {
            return await operation(cancellationToken);
        }

        var strategy = Database.CreateExecutionStrategy();
        var attempt = 0;

        return await strategy.ExecuteAsync(
            async token =>
            {
                // A retry replays the whole operation, so discard state tracked by the failed attempt.
                if (attempt++ > 0)
                {
                    ChangeTracker.Clear();
                }

                await using var transaction = await Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, token);

                var result = await operation(token);

                if (shouldCommit(result))
                {
                    await transaction.CommitAsync(token);
                }
                else
                {
                    await transaction.RollbackAsync(token);
                }

                return result;
            },
            cancellationToken);
    }

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        try
        {
            return base.SaveChanges(acceptAllChangesOnSuccess);
        }
        catch (Exception ex) when (TryTranslate(ex, out var translated))
        {
            throw translated;
        }
    }

    public override async Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
    {
        try
        {
            return await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
        }
        catch (Exception ex) when (TryTranslate(ex, out var translated))
        {
            throw translated;
        }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema(Schemas.Platform);

        // Trigram matching for multilingual product search (ILIKE '%term%'); pg_trgm is a trusted extension (PG13+),
        // so the database owner can create it without superuser rights.
        modelBuilder.HasPostgresExtension("pg_trgm");
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(MolBhavDbContext).Assembly);

        // Domain entities receive UUIDv7 ids in their factories; the database must never generate them.
        foreach (var entityType in modelBuilder.Model.GetEntityTypes().Where(t => t.BaseType is null && !t.IsOwned()))
        {
            if (IsDomainEntityWithGuidKey(entityType.ClrType))
            {
                modelBuilder.Entity(entityType.ClrType).Property(nameof(Entity<Guid>.Id)).ValueGeneratedNever();
            }
        }

        base.OnModelCreating(modelBuilder);
    }

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        configurationBuilder.Conventions.Add(_ => new SnakeCaseNamingConvention());

        // Domain events live in memory on aggregates and in the outbox as JSON — never as tables.
        configurationBuilder.IgnoreAny<IDomainEvent>();

        configurationBuilder.Properties<decimal>().HavePrecision(18, Money.Scale);

        // Enums as text: readable in SQL/reports and safe against member re-ordering.
        configurationBuilder.Properties<Enum>().HaveConversion<string>().HaveMaxLength(64);
    }

    private static bool IsDomainEntityWithGuidKey(Type type)
    {
        for (var current = type.BaseType; current is not null; current = current.BaseType)
        {
            if (current.IsGenericType && current.GetGenericTypeDefinition() == typeof(Entity<>))
            {
                return current.GetGenericArguments()[0] == typeof(Guid);
            }
        }

        return false;
    }

    /// <summary>Maps provider exceptions to application exceptions so upper layers stay persistence-agnostic.</summary>
    private static bool TryTranslate(Exception exception, out Exception translated)
    {
        switch (exception)
        {
            case DbUpdateConcurrencyException concurrency:
                translated = new ConcurrencyConflictException("The record was modified by another request. Reload and retry.", concurrency);
                return true;

            case DbUpdateException { InnerException: PostgresException { SqlState: PostgresErrorCodes.UniqueViolation } postgres } update:
                translated = new UniqueConstraintViolationException(postgres.ConstraintName, update);
                return true;

            default:
                translated = exception;
                return false;
        }
    }
}
