using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Watchlist.Models;

namespace MolBhav.Application.Features.Watchlist.GetWatchlist;

public sealed record GetWatchlistQuery : IQuery<IReadOnlyList<WatchlistItemResponse>>;
