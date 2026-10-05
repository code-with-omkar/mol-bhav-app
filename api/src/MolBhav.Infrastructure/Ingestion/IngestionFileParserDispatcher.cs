using Microsoft.Extensions.DependencyInjection;
using MolBhav.Application.Abstractions.Ingestion;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Picks the file parser for an upload — the counterpart of <see cref="IngestionAdapterDispatcher"/> for files:
/// <list type="number">
/// <item>A file whose header is the MolBhav standard template always goes to <see cref="StandardPriceCsvParser"/>, for any
/// source and any category — so a new category can take uploads the day its source is created, with no code.</item>
/// <item>Otherwise the parser registered keyed under the source code (e.g. <c>agmarknet</c> reads the government export
/// layouts).</item>
/// <item>No keyed parser → the standard parser, which explains which columns the template needs.</item>
/// </list>
/// The stream must be seekable (uploads are buffered by ASP.NET Core) because the header is peeked before parsing.
/// </summary>
internal sealed class IngestionFileParserDispatcher(IServiceProvider serviceProvider) : IIngestionFileParser
{
    public const string StandardKey = "__standard";

    public async Task<IngestionFileParseResult> ParseAsync(string sourceCode, Stream content, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(content);

        var standard = serviceProvider.GetRequiredKeyedService<IIngestionFileParser>(StandardKey);
        var keyed = serviceProvider.GetKeyedService<IIngestionFileParser>(sourceCode.ToLowerInvariant());
        if (keyed is null)
        {
            return await standard.ParseAsync(sourceCode, content, cancellationToken);
        }

        if (!content.CanSeek)
        {
            return await keyed.ParseAsync(sourceCode, content, cancellationToken);
        }

        var start = content.Position;
        var isStandard = await StandardPriceCsvParser.LooksLikeTemplateAsync(content, cancellationToken);
        content.Position = start;

        return isStandard
            ? await standard.ParseAsync(sourceCode, content, cancellationToken)
            : await keyed.ParseAsync(sourceCode, content, cancellationToken);
    }
}
