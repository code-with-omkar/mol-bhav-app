using System.Data.Common;
using Npgsql;

namespace MolBhav.Infrastructure.Persistence.Read;

/// <summary>Shares the singleton <see cref="NpgsqlDataSource"/> (and its pool) with EF Core.</summary>
internal sealed class NpgsqlConnectionFactory(NpgsqlDataSource dataSource) : IDbConnectionFactory
{
    public async ValueTask<DbConnection> OpenConnectionAsync(CancellationToken cancellationToken = default) =>
        await dataSource.OpenConnectionAsync(cancellationToken);
}
