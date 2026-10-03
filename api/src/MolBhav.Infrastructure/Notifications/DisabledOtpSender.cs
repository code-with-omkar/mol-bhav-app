using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>
/// Registered when OTP login is switched off, so no SMS provider (or its secrets) is required. The OTP handlers refuse
/// before reaching the sender; reaching this is a wiring bug, hence the exception rather than a silent no-op.
/// </summary>
internal sealed class DisabledOtpSender : IOtpSender
{
    public Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default) =>
        throw new InvalidOperationException("OTP login is disabled (Authentication:LoginMethods:Otp = false); no OTP may be sent.");
}
