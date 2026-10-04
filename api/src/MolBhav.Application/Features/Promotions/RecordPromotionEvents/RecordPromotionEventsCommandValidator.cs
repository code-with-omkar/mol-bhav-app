using FluentValidation;

namespace MolBhav.Application.Features.Promotions.RecordPromotionEvents;

internal sealed class RecordPromotionEventsCommandValidator : AbstractValidator<RecordPromotionEventsCommand>
{
    public const int MaxEvents = 50;

    public RecordPromotionEventsCommandValidator()
    {
        RuleFor(x => x.Events).NotNull().Must(e => e is { Count: > 0 and <= MaxEvents })
            .WithMessage($"Send between 1 and {MaxEvents} events.");
        RuleForEach(x => x.Events).ChildRules(e =>
        {
            e.RuleFor(x => x.CampaignId).NotEmpty();
            e.RuleFor(x => x.Type).NotNull().IsInEnum();
        });
    }
}
