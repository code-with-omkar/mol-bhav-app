using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Features.Market.Admin.ImportFeedMarkets;

/// <summary>
/// Adds markets from a price source's feed to the catalog as mandis: for one state, each named market gets a mandi
/// (and its district, when the catalog lacks it) whose code is the one ingestion will look prices up under.
/// </summary>
public sealed record ImportFeedMarketsCommand(Guid PriceSourceId, string? State, IReadOnlyList<string>? Markets)
    : ICommand<ImportFeedMarketsResponse>;
