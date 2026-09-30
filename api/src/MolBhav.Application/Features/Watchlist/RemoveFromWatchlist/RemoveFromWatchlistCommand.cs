using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Watchlist.RemoveFromWatchlist;

public sealed record RemoveFromWatchlistCommand(Guid WatchlistItemId) : ICommand;
