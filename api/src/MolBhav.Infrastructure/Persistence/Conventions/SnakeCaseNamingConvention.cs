using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Metadata.Conventions;

namespace MolBhav.Infrastructure.Persistence.Conventions;

/// <summary>
/// Rewrites tables, columns, keys, FKs and indexes to snake_case at model finalisation so raw SQL/Dapper
/// never needs quoted identifiers. Runs at convention level: any name set explicitly via fluent API is kept as-is.
/// Implemented in-house to avoid a third-party dependency on a model-building hot path.
/// </summary>
internal sealed class SnakeCaseNamingConvention : IModelFinalizingConvention
{
    public void ProcessModelFinalizing(IConventionModelBuilder modelBuilder, IConventionContext<IConventionModelBuilder> context)
    {
        foreach (var entityType in modelBuilder.Metadata.GetEntityTypes())
        {
            // JSON-mapped owned types use JSON property names, not columns.
            if (entityType.IsMappedToJson())
            {
                continue;
            }

            var tableName = entityType.GetTableName();
            if (tableName is not null)
            {
                entityType.Builder.ToTable(SnakeCaseNameRewriter.Rewrite(tableName));
            }

            // Resolve column names against the (renamed) table so complex-type columns keep their
            // owner prefix (TargetPrice.Amount → target_price_amount) instead of colliding as "amount".
            var table = StoreObjectIdentifier.Create(entityType, StoreObjectType.Table);

            foreach (var property in entityType.GetDeclaredProperties())
            {
                RenameColumn(property, table);
            }

            foreach (var complexProperty in entityType.GetDeclaredComplexProperties())
            {
                RenameComplexColumns(complexProperty, table);
            }
        }

        // Constraint/index default names derive from table + column names, so rename them after all columns.
        foreach (var entityType in modelBuilder.Metadata.GetEntityTypes())
        {
            if (entityType.IsMappedToJson())
            {
                continue;
            }

            foreach (var key in entityType.GetDeclaredKeys())
            {
                var name = key.GetName();
                if (name is not null)
                {
                    key.Builder.HasName(SnakeCaseNameRewriter.Rewrite(name));
                }
            }

            foreach (var foreignKey in entityType.GetDeclaredForeignKeys())
            {
                var name = foreignKey.GetConstraintName();
                if (name is not null)
                {
                    foreignKey.Builder.HasConstraintName(SnakeCaseNameRewriter.Rewrite(name));
                }
            }

            foreach (var index in entityType.GetDeclaredIndexes())
            {
                var name = index.GetDatabaseName();
                if (name is not null)
                {
                    index.Builder.HasDatabaseName(SnakeCaseNameRewriter.Rewrite(name));
                }
            }
        }
    }

    private static void RenameColumn(IConventionProperty property, StoreObjectIdentifier? table)
    {
        var columnName = table is { } storeObject ? property.GetColumnName(storeObject) : property.GetColumnName();
        if (!string.IsNullOrEmpty(columnName))
        {
            property.Builder.HasColumnName(SnakeCaseNameRewriter.Rewrite(columnName));
        }
    }

    private static void RenameComplexColumns(IConventionComplexProperty complexProperty, StoreObjectIdentifier? table)
    {
        foreach (var property in complexProperty.ComplexType.GetDeclaredProperties())
        {
            RenameColumn(property, table);
        }

        foreach (var nested in complexProperty.ComplexType.GetDeclaredComplexProperties())
        {
            RenameComplexColumns(nested, table);
        }
    }
}
