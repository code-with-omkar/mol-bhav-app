using Dapper;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Infrastructure.Persistence.Configurations.Catalog;

namespace MolBhav.Infrastructure.Persistence.Read.Catalog;

internal sealed class ProcurementCategoryLookup(IDbConnectionFactory connectionFactory) : IProcurementCategoryLookup
{
    // Npgsql passes the string[] as a native text[] parameter; the alternate key on code serves the lookup.
    private const string Sql = $"""
        SELECT c.code
        FROM {Schemas.Catalog}.{ProcurementCategoryConfiguration.TableName} c
        WHERE c.is_active AND c.code = ANY(@Codes);
        """;

    public async Task<IReadOnlySet<string>> GetActiveCodesAsync(IReadOnlyCollection<string> codes, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(codes);

        if (codes.Count == 0)
        {
            return new HashSet<string>(StringComparer.Ordinal);
        }

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var found = await connection.QueryAsync<string>(
            new CommandDefinition(Sql, new { Codes = codes.ToArray() }, cancellationToken: cancellationToken));

        return found.ToHashSet(StringComparer.Ordinal);
    }
}
