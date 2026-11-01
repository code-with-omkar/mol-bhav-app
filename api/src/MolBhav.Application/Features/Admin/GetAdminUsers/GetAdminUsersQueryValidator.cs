using FluentValidation;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Admin.GetAdminUsers;

internal sealed class GetAdminUsersQueryValidator : AbstractValidator<GetAdminUsersQuery>
{
    public const int SearchMaxLength = 50;

    public GetAdminUsersQueryValidator()
    {
        RuleFor(x => x.Search).MaximumLength(SearchMaxLength);
        RuleFor(x => x.Status).IsInEnum().When(x => x.Status is not null);
        RuleFor(x => x.Tier).IsInEnum().When(x => x.Tier is not null);
    }
}
