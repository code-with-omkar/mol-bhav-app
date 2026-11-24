using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Market.Admin.ImportAllFeedMarkets;

/// <summary>What adding every market in the feed did. States and markets already in the catalog are left alone.</summary>
public sealed record ImportAllFeedMarketsResponse(int StatesCreated, int MarketsCreated, int AlreadyInCatalog, int Other);

/// <summary>
/// Adds every market in a price source's saved feed list to the catalog: states the catalog lacks are created, then each
/// state's markets (and their districts) are added as mandis under the code ingestion looks prices up by.
/// </summary>
public sealed record ImportAllFeedMarketsCommand(Guid PriceSourceId) : ICommand<ImportAllFeedMarketsResponse>, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Market.ImportFeedAll";

    string? IAuditedCommand.AuditTarget => PriceSourceId.ToString();

    string IAuditedCommand.AuditSummary => "Added every market from the feed to the catalog";
}
