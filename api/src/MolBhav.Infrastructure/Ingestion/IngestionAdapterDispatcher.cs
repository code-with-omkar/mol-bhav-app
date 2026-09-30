using Microsoft.Extensions.DependencyInjection;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Routes each fetch to the keyed adapter registered under <see cref="IngestionFetchRequest.SourceCode"/>
/// (e.g. <c>agmarknet</c>); sources with no real adapter fall back to <see cref="StubIngestionSourceAdapter"/>.
/// </summary>
internal sealed class IngestionAdapterDispatcher(IServiceProvider serviceProvider) : IIngestionSourceAdapter
{
    public const string FallbackKey = "__stub";

    public Task<IngestionFetchResult> FetchAsync(IngestionFetchRequest request, CancellationToken cancellationToken = default)
    {
        var adapter = serviceProvider.GetKeyedService<IIngestionSourceAdapter>(request.SourceCode.ToLowerInvariant())
            ?? serviceProvider.GetRequiredKeyedService<IIngestionSourceAdapter>(FallbackKey);

        return adapter.FetchAsync(request, cancellationToken);
    }
}
