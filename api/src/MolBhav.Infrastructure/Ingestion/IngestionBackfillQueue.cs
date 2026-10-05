using System.Threading.Channels;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>Bounded in-process queue; <see cref="IngestionBackfillBackgroundService"/> drains it.</summary>
internal sealed class IngestionBackfillQueue : IIngestionBackfillQueue
{
    /// <summary>Waiting backfills, not days — each request can hold up to a month of dates.</summary>
    public const int Capacity = 5;

    private readonly Channel<IngestionBackfillRequest> _channel = Channel.CreateBounded<IngestionBackfillRequest>(
        new BoundedChannelOptions(Capacity)
        {
            FullMode = BoundedChannelFullMode.Wait, // TryWrite returns false instead of dropping.
            SingleReader = true,
            SingleWriter = false,
        });

    public ChannelReader<IngestionBackfillRequest> Reader => _channel.Reader;

    public bool TryEnqueue(IngestionBackfillRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);
        return _channel.Writer.TryWrite(request);
    }
}
