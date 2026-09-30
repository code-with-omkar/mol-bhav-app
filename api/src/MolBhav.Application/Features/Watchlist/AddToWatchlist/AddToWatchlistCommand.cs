using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Watchlist.AddToWatchlist;

public sealed record AddToWatchlistCommand(Guid ProductId, Guid? VariantId) : ICommand<CreatedResponse>;
