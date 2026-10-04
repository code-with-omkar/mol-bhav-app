using FluentValidation;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Admin;

/// <summary>Shape checks; the domain enforces lengths, schedule order and URL schemes.</summary>
internal sealed class CampaignInputValidator : AbstractValidator<CampaignInput>
{
    public CampaignInputValidator()
    {
        RuleFor(x => x.Name).NotEmpty();
        RuleFor(x => x.Placement).NotNull().IsInEnum();
        RuleFor(x => x.Title).NotEmpty();
        RuleFor(x => x.Body).NotEmpty();
        RuleFor(x => x.CtaLabel).NotEmpty();
        RuleFor(x => x.CtaUrl).NotEmpty();
        RuleFor(x => x.StartsAtUtc).NotNull();
        RuleFor(x => x.EndsAtUtc).NotNull();
        RuleFor(x => x.Priority).InclusiveBetween(0, Campaign.MaxPriority).When(x => x.Priority is not null);
        RuleFor(x => x.Targets).NotEmpty();
        RuleForEach(x => x.Targets).NotNull().ChildRules(t => t.RuleFor(x => x.CategoryCode).NotEmpty());
    }
}
