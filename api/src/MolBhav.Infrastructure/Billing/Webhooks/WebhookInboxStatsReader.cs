using Dapper;
using MolBhav.Infrastructure.Persistence.Read;

namespace MolBhav.Infrastructure.Billing.Webhooks;

/// <summary>
/// One round trip for the inbox snapshot. Every sub-select is shaped to hit a partial index from
/// <c>AddBillingWebhookInbox</c> (pending: <c>ix_webhook_inbox_next_attempt_at_utc</c>; parked:
/// <c>ix_webhook_inbox_parked_at_utc</c>), so the cost tracks the size of the queue, not the processed history.
/// </summary>
internal sealed class WebhookInboxStatsReader(IDbConnectionFactory connectionFactory, TimeProvider timeProvider)
{
    private const string Table = WebhookInboxMessageConfiguration.QualifiedTableName;
    private const string PendingFilter = "processed_at_utc IS NULL AND parked_at_utc IS NULL";

    private const string StatsSql = $"""
        SELECT
            (SELECT count(*) FROM {Table} WHERE {PendingFilter}) AS pending,
            (SELECT min(next_attempt_at_utc) FROM {Table} WHERE {PendingFilter}) AS earliest_next_attempt_at_utc,
            (SELECT count(*) FROM {Table} WHERE parked_at_utc IS NOT NULL) AS parked,
            (SELECT count(*) FROM {Table} WHERE parked_at_utc IS NOT NULL AND parked_at_utc >= @ParkedSince) AS parked_last_24_hours;
        """;

    public async Task<WebhookInboxStats> ReadAsync(CancellationToken cancellationToken)
    {
        var nowUtc = timeProvider.GetUtcNow();

        await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleAsync<StatsRow>(
            new CommandDefinition(StatsSql, new { ParkedSince = nowUtc.AddHours(-24) }, cancellationToken: cancellationToken));

        var overdueLagSeconds = row.EarliestNextAttemptAtUtc is { } due && due < nowUtc ? (nowUtc - due).TotalSeconds : 0;

        return new WebhookInboxStats(row.Pending, overdueLagSeconds, row.Parked, row.ParkedLast24Hours, nowUtc);
    }

#pragma warning disable CA1812 // Instantiated by Dapper.
    private sealed class StatsRow
    {
        public long Pending { get; init; }

        public DateTimeOffset? EarliestNextAttemptAtUtc { get; init; }

        public long Parked { get; init; }

        public long ParkedLast24Hours { get; init; }
    }
#pragma warning restore CA1812
}
