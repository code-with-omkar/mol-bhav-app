using System.Data.Common;

namespace MolBhav.Infrastructure.Persistence.Read;

/// <summary>
/// Opens pooled connections for Dapper read services (dashboards, comparison matrices, trends, exports).
/// Read services live in Infrastructure and implement query interfaces declared by Application features,
/// so SQL never leaks into the Application layer. Always use parameterised SQL.
/// </summary>
internal interface IDbConnectionFactory
{
    ValueTask<DbConnection> OpenConnectionAsync(CancellationToken cancellationToken = default);
}
