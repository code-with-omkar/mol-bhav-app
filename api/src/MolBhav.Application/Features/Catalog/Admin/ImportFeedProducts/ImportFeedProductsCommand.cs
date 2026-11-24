using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.ImportFeedProducts;

/// <summary>
/// Adds commodities from a price source's feed to the catalog as products, all under one sub-category and priced in
/// one unit, each with the code ingestion will look prices up under and its English name from the feed.
/// </summary>
public sealed record ImportFeedProductsCommand(
    Guid PriceSourceId,
    Guid SubCategoryId,
    Guid DefaultUnitId,
    IReadOnlyList<string>? Commodities) : ICommand<ImportFeedProductsResponse>, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Catalog.ImportFeed";

    string? IAuditedCommand.AuditTarget => SubCategoryId.ToString();

    string IAuditedCommand.AuditSummary => $"Added feed commodities to the catalog ({Commodities?.Count ?? 0} chosen)";
}
