using FluentValidation;

namespace MolBhav.Application.Features.Promotions.GetPromotion;

internal sealed class GetPromotionQueryValidator : AbstractValidator<GetPromotionQuery>
{
    public GetPromotionQueryValidator() => RuleFor(x => x.Placement).NotNull().IsInEnum();
}
