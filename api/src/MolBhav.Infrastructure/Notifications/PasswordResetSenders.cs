using System.Net.Http.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>"Forgot password" delivery, from the <c>PasswordReset</c> configuration section.</summary>
public sealed class PasswordResetOptions
{
    public const string SectionName = "PasswordReset";

    /// <summary>Off by default: switch on once a channel can really deliver codes.</summary>
    public bool Enabled { get; set; }

    /// <summary><c>WhatsApp</c>, or <c>Log</c> (Development only: the code is written to the API log).</summary>
    public string Channel { get; set; } = "WhatsApp";

    /// <summary>An approved Meta template of the <b>Authentication</b> category.</summary>
    public string TemplateName { get; set; } = "molbhav_otp";

    /// <summary>Language code exactly as approved, e.g. <c>en</c> or <c>en_US</c>.</summary>
    public string TemplateLanguage { get; set; } = "en";
}

internal sealed class DisabledPasswordResetSender : IPasswordResetCodeSender
{
    public bool IsEnabled => false;

    public Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default) => Task.CompletedTask;
}

/// <summary>Development only (startup refuses it elsewhere): writes the code to the log so the flow can be tried.</summary>
internal sealed partial class LoggingPasswordResetSender(ILogger<LoggingPasswordResetSender> logger) : IPasswordResetCodeSender
{
    public bool IsEnabled => true;

    public Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(phoneNumber);
        LogCode(logger, phoneNumber.Masked, code);
        return Task.CompletedTask;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "[DEV password reset] Code for {PhoneNumber}: {Code}")]
    private static partial void LogCode(ILogger logger, string phoneNumber, string code);
}

/// <summary>
/// Sends the code with a WhatsApp authentication template. Meta fixes that template's text; the code goes in the body
/// and again in its "copy code" button.
/// </summary>
internal sealed partial class WhatsAppPasswordResetSender(
    IHttpClientFactory httpClientFactory,
    IOptions<WhatsAppOptions> whatsApp,
    IOptions<PasswordResetOptions> options,
    ILogger<WhatsAppPasswordResetSender> logger) : IPasswordResetCodeSender
{
    public bool IsEnabled => true;

    public async Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(phoneNumber);

        var parameters = new[] { new { type = "text", text = code } };
        var payload = new
        {
            messaging_product = "whatsapp",
            to = phoneNumber.Value.TrimStart('+'),
            type = "template",
            template = new
            {
                name = options.Value.TemplateName,
                language = new { code = options.Value.TemplateLanguage },
                components = new object[]
                {
                    new { type = "body", parameters },
                    new { type = "button", sub_type = "url", index = "0", parameters },
                },
            },
        };

        try
        {
            var client = httpClientFactory.CreateClient(WhatsAppCloudSender.HttpClientName);
            using var response = await client.PostAsJsonAsync(
                $"{whatsApp.Value.ApiVersion}/{whatsApp.Value.PhoneNumberId}/messages", payload, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                // Meta's error text names the problem (template, token, recipient); it does not contain the code.
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                LogRejected(logger, phoneNumber.Masked, (int)response.StatusCode, body);
            }
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException && !cancellationToken.IsCancellationRequested)
        {
            LogFailed(logger, phoneNumber.Masked, ex);
        }
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Password reset code for {PhoneNumber} was rejected by WhatsApp ({Status}): {Body}")]
    private static partial void LogRejected(ILogger logger, string phoneNumber, int status, string body);

    [LoggerMessage(Level = LogLevel.Error, Message = "Password reset code for {PhoneNumber} could not be sent")]
    private static partial void LogFailed(ILogger logger, string phoneNumber, Exception exception);
}
