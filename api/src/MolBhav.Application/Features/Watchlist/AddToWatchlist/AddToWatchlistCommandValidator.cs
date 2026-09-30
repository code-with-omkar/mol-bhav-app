using FluentValidation;

namespace MolBhav.Application.Features.Watchlist.AddToWatchlist;

internal sealed class AddToWatchlistCommandValidator : AbstractValidator<AddToWatchlistCommand>
{
    public AddToWatchlistCommandValidator() => RuleFor(x => x.ProductId).NotEmpty();
}
