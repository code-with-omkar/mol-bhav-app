using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Infrastructure.Persistence.Configurations;

/// <summary>Building blocks every <c>IEntityTypeConfiguration</c> composes, so conventions stay uniform across modules.</summary>
internal static class EntityTypeBuilderExtensions
{
    /// <summary>PostgreSQL system column used as an optimistic-concurrency token (no extra column, updated by the server).</summary>
    public const string ConcurrencyTokenName = "xmin";

    /// <summary>
    /// Places the entity in a module schema while leaving the table name to the snake_case convention
    /// (calling <c>ToTable(name, schema)</c> would pin the name explicitly and bypass the convention).
    /// </summary>
    public static EntityTypeBuilder<TEntity> InSchema<TEntity>(this EntityTypeBuilder<TEntity> builder, string schema)
        where TEntity : class
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(schema);
        builder.Metadata.SetSchema(schema);
        return builder;
    }

    /// <summary>Key (application-generated UUIDv7 — time-ordered, index-friendly), concurrency token, no domain-event mapping.</summary>
    public static EntityTypeBuilder<TAggregate> ConfigureAggregateRoot<TAggregate>(this EntityTypeBuilder<TAggregate> builder)
        where TAggregate : AggregateRoot<Guid>
    {
        builder.HasKey(a => a.Id);
        builder.Property(a => a.Id).ValueGeneratedNever();
        builder.Ignore(a => a.DomainEvents);
        builder.HasConcurrencyToken();
        return builder;
    }

    public static EntityTypeBuilder<TEntity> HasConcurrencyToken<TEntity>(this EntityTypeBuilder<TEntity> builder)
        where TEntity : class
    {
        builder.Property<uint>(ConcurrencyTokenName)
            .HasColumnName(ConcurrencyTokenName)
            .HasColumnType("xid")
            .ValueGeneratedOnAddOrUpdate()
            .IsConcurrencyToken();
        return builder;
    }

    public static EntityTypeBuilder<TEntity> ConfigureAuditing<TEntity>(this EntityTypeBuilder<TEntity> builder)
        where TEntity : class, IAuditableEntity
    {
        builder.Property(e => e.CreatedAtUtc).IsRequired();
        builder.Property(e => e.CreatedBy);
        builder.Property(e => e.UpdatedAtUtc);
        builder.Property(e => e.UpdatedBy);
        return builder;
    }

    /// <summary>
    /// Soft-delete columns + global filter. Call <c>IgnoreQueryFilters()</c> explicitly (admin/restore paths) to see deleted rows.
    /// Unique indexes on soft-deletable tables must be filtered with <c>HasFilter("is_deleted = false")</c>.
    /// </summary>
    public static EntityTypeBuilder<TEntity> ConfigureSoftDelete<TEntity>(this EntityTypeBuilder<TEntity> builder)
        where TEntity : class, ISoftDeletable
    {
        builder.Property(e => e.IsDeleted).IsRequired();
        builder.Property(e => e.DeletedAtUtc);
        builder.Property(e => e.DeletedBy);
        builder.HasQueryFilter(e => !EF.Property<bool>(e, nameof(ISoftDeletable.IsDeleted)));
        return builder;
    }
}
