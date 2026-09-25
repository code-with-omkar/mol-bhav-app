using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Abstractions.Notifications;

/// <summary>
/// Delivers an OTP code to a phone number (SMS/WhatsApp). Called synchronously from the command handler rather
/// than routed through the transactional outbox: the outbox persists its payload (even if briefly), and this
/// message's payload would have to carry the plaintext code — exactly what <c>OtpChallenge</c> deliberately never
/// stores. A short send-but-DB-rolls-back race is the accepted, industry-standard trade-off for OTP delivery.
/// </summary>
public interface IOtpSender
{
    Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default);
}
