using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Stand-in <see cref="IIngestionSourceAdapter"/> until real Agmarknet/data.gov.in (agriculture) and WPI/CPWD/data.gov.in
/// (construction) HTTP clients are wired up (BRD §9 — data model + admin CRUD only, per scope): always returns a
/// failed outcome with an honest, specific reason rather than fabricating price data. Swap this registration for
/// real per-source clients in <c>DependencyInjection.AddIngestionModule</c> when they're available — e.g. resolve
/// by <see cref="IngestionFetchRequest.SourceCode"/> to pick an Agmarknet adapter vs a CPWD adapter.
/// </summary>
internal sealed partial class StubIngestionSourceAdapter(ILogger<StubIngestionSourceAdapter> logger) : IIngestionSourceAdapter
{
    public Task<IngestionFetchResult> FetchAsync(IngestionFetchRequest request, CancellationToken cancellationToken = default)
    {
        LogRequested(logger, request.SourceCode, request.AsOfDate);

        return Task.FromResult(IngestionFetchResult.Failed(
            $"No ingestion adapter is configured for source '{request.SourceCode}' yet. Wire up IIngestionSourceAdapter with a real client to enable this."));
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "[STUB INGESTION] Requested fetch for source {SourceCode} as of {AsOfDate} — no adapter configured")]
    private static partial void LogRequested(ILogger logger, string sourceCode, DateOnly asOfDate);
}
