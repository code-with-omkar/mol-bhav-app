using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Notification.RecordWhatsAppDeliveryStatus;

/// <summary>What Meta reported about a message after accepting it.</summary>
public enum WhatsAppDeliveryState
{
    Delivered,
    Failed,
}

/// <summary>
/// A delivery receipt from the WhatsApp Cloud API webhook, matched to the notification by the <c>wamid</c> Meta
/// returned when the message was accepted. <paramref name="Error"/> carries Meta's code and title for failures
/// (e.g. 131030 "Recipient phone number not in allowed list").
/// </summary>
public sealed record RecordWhatsAppDeliveryStatusCommand(
    string ProviderMessageId,
    WhatsAppDeliveryState State,
    string? Error,
    DateTimeOffset At) : ICommand;
