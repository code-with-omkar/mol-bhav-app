using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Features.Market.Admin.ImportFeedMarkets;

/// <summary>
/// Adds markets from a price source's feed to the catalog as mandis: for one state, each named market gets a mandi
/// (and its district, when the catalog lacks it) whose code is the one ingestion will look prices up under.
/// </summary>
public sealed record ImportFeedMarketsCommand(Guid PriceSourceId, string? State, IReadOnlyList<string>? Markets)
    : ICommand<ImportFeedMarketsResponse>, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Market.ImportFeed";

    string? IAuditedCommand.AuditTarget => State?.Trim();

    string IAuditedCommand.AuditSummary => $"Added feed markets for {State?.Trim()} ({Markets?.Count ?? 0} chosen)";
}
