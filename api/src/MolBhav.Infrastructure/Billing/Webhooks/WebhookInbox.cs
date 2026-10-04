using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Infrastructure.Persistence;

namespace MolBhav.Infrastructure.Billing.Webhooks;

/// <summary>
/// One statement, no read-then-write race: <c>ON CONFLICT DO NOTHING</c> on the (provider, event_id) unique index makes
/// concurrent redeliveries of the same event collapse to a single row, and the affected-row count says which call won.
/// Runs on the caller's DbContext, so it joins the command's unit-of-work transaction.
/// </summary>
internal sealed class WebhookInbox(MolBhavDbContext dbContext, TimeProvider timeProvider) : IWebhookInbox
{
    // Identifier comes from compile-time constants (never user input); every value is bound as a parameter.
    private const string InsertSql =
        "INSERT INTO " + WebhookInboxMessageConfiguration.QualifiedTableName +
        " (id, provider, event_id, event_type, payload, received_at_utc, next_attempt_at_utc, attempt_count)" +
        " VALUES ({0}, {1}, {2}, {3}, CAST({4} AS jsonb), {5}, {5}, 0)" +
        " ON CONFLICT (provider, event_id) DO NOTHING";

    public async Task<bool> TryEnqueueAsync(
        string provider,
        string eventId,
        string eventType,
        string payload,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(provider);
        ArgumentException.ThrowIfNullOrWhiteSpace(eventId);
        ArgumentException.ThrowIfNullOrWhiteSpace(eventType);
        ArgumentException.ThrowIfNullOrWhiteSpace(payload);

        var nowUtc = timeProvider.GetUtcNow();

        var inserted = await dbContext.Database.ExecuteSqlRawAsync(
            InsertSql,
            new object[] { Guid.CreateVersion7(nowUtc), provider, eventId, eventType, payload, nowUtc },
            cancellationToken);

        return inserted == 1;
    }
}
