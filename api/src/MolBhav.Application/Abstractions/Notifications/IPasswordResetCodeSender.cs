using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Abstractions.Notifications;

/// <summary>
/// Delivers a password reset code to a phone number. Separate from <see cref="IOtpSender"/> so "forgot password" can be
/// on (over WhatsApp) while SMS code login stays off. Like that one it is called directly, never through the outbox,
/// which would have to store the plain code.
/// </summary>
public interface IPasswordResetCodeSender
{
    /// <summary>False when this deployment offers no way to reset a password.</summary>
    bool IsEnabled { get; }

    /// <summary>Never throws for a delivery problem: an error only for real accounts would reveal which numbers have one.</summary>
    Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default);
}
