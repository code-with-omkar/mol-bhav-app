using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Watchlist;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Watchlist.RemoveFromWatchlist;

internal sealed class RemoveFromWatchlistCommandHandler(IWatchlistItemRepository watchlistItems, ICurrentUser currentUser)
    : ICommandHandler<RemoveFromWatchlistCommand>
{
    public async Task<Result> Handle(RemoveFromWatchlistCommand request, CancellationToken cancellationToken)
    {
        var item = await watchlistItems.GetByIdAsync(request.WatchlistItemId, cancellationToken);
        if (item is null || item.UserId != currentUser.GetRequiredUserId())
        {
            // Same 404 whether it's someone else's item or doesn't exist — never reveal other users' data.
            return Error.NotFound("WatchlistItem.NotFound", "Watchlist item not found.");
        }

        watchlistItems.Remove(item);
        return Result.Success();
    }
}
