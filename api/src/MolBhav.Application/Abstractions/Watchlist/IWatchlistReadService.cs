using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Features.Watchlist.Models;

namespace MolBhav.Application.Abstractions.Watchlist;

/// <summary>Dapper-backed reads for the signed-in user's watchlist, reusing the catalog's language-fallback naming.</summary>
public interface IWatchlistReadService
{
    Task<IReadOnlyList<WatchlistItemResponse>> GetWatchlistAsync(Guid userId, LanguagePreference language, CancellationToken cancellationToken = default);
}
