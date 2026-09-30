using FluentValidation;

namespace MolBhav.Application.Features.Notification.UpdateNotificationPreferences;

internal sealed class UpdateNotificationPreferencesCommandValidator
    : AbstractValidator<UpdateNotificationPreferencesCommand>
{
    public UpdateNotificationPreferencesCommandValidator()
    {
        // Sub-toggles must not be enabled when the master toggle is off.
        RuleFor(x => x)
            .Must(x => !x.AlertPushEnabled || x.PushEnabled)
            .WithName(nameof(UpdateNotificationPreferencesCommand.AlertPushEnabled))
            .WithMessage("AlertPushEnabled requires PushEnabled to be true.");

        RuleFor(x => x)
            .Must(x => !x.PriceUpdatePushEnabled || x.PushEnabled)
            .WithName(nameof(UpdateNotificationPreferencesCommand.PriceUpdatePushEnabled))
            .WithMessage("PriceUpdatePushEnabled requires PushEnabled to be true.");

        RuleFor(x => x)
            .Must(x => !x.AlertWhatsAppEnabled || x.WhatsAppEnabled)
            .WithName(nameof(UpdateNotificationPreferencesCommand.AlertWhatsAppEnabled))
            .WithMessage("AlertWhatsAppEnabled requires WhatsAppEnabled to be true.");
    }
}
