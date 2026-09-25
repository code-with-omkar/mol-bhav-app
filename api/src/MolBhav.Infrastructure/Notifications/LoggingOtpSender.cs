using Microsoft.Extensions.Logging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>
/// Development-only <see cref="IOtpSender"/>: writes the code to the log so the login flow can be exercised end-to-end
/// from Postman/the emulator before an SMS/WhatsApp gateway is contracted. Registration is guarded in
/// <c>DependencyInjection</c> — the host refuses to start with this provider outside the Development environment.
/// </summary>
internal sealed partial class LoggingOtpSender(ILogger<LoggingOtpSender> logger) : IOtpSender
{
    public Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(phoneNumber);
        ArgumentException.ThrowIfNullOrWhiteSpace(code);

        LogCode(logger, phoneNumber.Masked, code);
        return Task.CompletedTask;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "[DEV OTP] Code for {PhoneNumber}: {Code}")]
    private static partial void LogCode(ILogger logger, string phoneNumber, string code);
}
