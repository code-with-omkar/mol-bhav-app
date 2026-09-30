using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Watchlist;
using MolBhav.Application.Features.Catalog;
using MolBhav.Application.Features.Watchlist.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Watchlist.GetWatchlist;

internal sealed class GetWatchlistQueryHandler(IWatchlistReadService readService, ICurrentUser currentUser, ILanguageContext languageContext)
    : IQueryHandler<GetWatchlistQuery, IReadOnlyList<WatchlistItemResponse>>
{
    public async Task<Result<IReadOnlyList<WatchlistItemResponse>>> Handle(GetWatchlistQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetWatchlistAsync(currentUser.GetRequiredUserId(), CatalogLanguage.From(languageContext), cancellationToken));
}
