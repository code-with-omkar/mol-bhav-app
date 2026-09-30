using FluentValidation;

namespace MolBhav.Application.Features.Billing.ActivateSubscription;

internal sealed class ActivateSubscriptionCommandValidator : AbstractValidator<ActivateSubscriptionCommand>
{
    public ActivateSubscriptionCommandValidator()
    {
        RuleFor(x => x.RazorpayOrderId).NotEmpty().MaximumLength(50);
        RuleFor(x => x.RazorpayPaymentId).NotEmpty().MaximumLength(50);
        RuleFor(x => x.RazorpaySignature).NotEmpty().MaximumLength(512);
    }
}
