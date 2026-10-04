using FluentValidation;

namespace MolBhav.Application.Features.Billing.Webhook;

internal sealed class ReceiveRazorpayWebhookCommandValidator : AbstractValidator<ReceiveRazorpayWebhookCommand>
{
    /// <summary>Matches the inbox <c>event_id</c> column.</summary>
    public const int EventIdMaxLength = 100;

    public ReceiveRazorpayWebhookCommandValidator()
    {
        // Razorpay sends x-razorpay-event-id on every delivery; without it a redelivery can't be told from a new event.
        RuleFor(x => x.EventId).NotEmpty().MaximumLength(EventIdMaxLength);
        RuleFor(x => x.RawBody).NotEmpty();
    }
}
