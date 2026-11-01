using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Ingestion.Models;

namespace MolBhav.Application.Features.Ingestion.Admin.GetSourceFeedOptions;

/// <summary>The states, markets and commodities a source's last full pull saw — the choices for a filtered manual run.</summary>
public sealed record GetSourceFeedOptionsQuery(Guid PriceSourceId) : IQuery<SourceFeedOptionsResponse>;
