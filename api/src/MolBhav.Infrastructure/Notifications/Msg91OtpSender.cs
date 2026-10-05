using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>
/// Delivers an OTP via the MSG91 OTP API v5. Registered only when <c>OtpDelivery:Provider</c> is <c>Msg91</c>
/// and <c>OtpDelivery:Msg91:AuthKey</c> is non-empty. Falls back to <see cref="LoggingOtpSender"/> in Development
/// when the key is absent (see <c>DependencyInjection.AddIdentityModule</c>).
/// </summary>
/// <remarks>
/// MSG91 reports most failures (bad template, DLT mismatch, IP not whitelisted, invalid authkey) as HTTP 200 with
/// <c>{"type":"error","message":"..."}</c>, so the body is inspected as well as the status code.
/// </remarks>
internal sealed partial class Msg91OtpSender(
    IHttpClientFactory httpClientFactory,
    IOptions<Msg91Options> options,
    ILogger<Msg91OtpSender> logger) : IOtpSender
{
    public const string HttpClientName = "msg91";

    private static readonly Uri OtpEndpoint = new("api/v5/otp", UriKind.Relative);

    public async Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(phoneNumber);
        ArgumentException.ThrowIfNullOrWhiteSpace(code);

        var opts = options.Value;

        // PhoneNumber.Value is E.164 (+91XXXXXXXXXX). MSG91 expects the number without the leading '+'.
        var mobile = phoneNumber.Value.TrimStart('+');

        var payload = new
        {
            template_id = opts.TemplateId,
            mobile,
            authkey = opts.AuthKey,
            otp = code,
        };

        var client = httpClientFactory.CreateClient(HttpClientName);
        using var request = new HttpRequestMessage(HttpMethod.Post, OtpEndpoint)
        {
            Content = JsonContent.Create(payload),
        };
        request.Headers.TryAddWithoutValidation("authkey", opts.AuthKey);

        using var response = await client.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);

        // Masked once up front: both outcomes log it, and a plain local keeps CA1873 quiet.
        var maskedMobile = MaskMobile(mobile);

        if (!response.IsSuccessStatusCode || !IsSuccessBody(body))
        {
            LogDeliveryFailed(logger, maskedMobile, (int)response.StatusCode, body);
            throw new OtpDeliveryException((int)response.StatusCode, body);
        }

        LogAccepted(logger, maskedMobile, body);
    }

    private static bool IsSuccessBody(string body)
    {
        if (string.IsNullOrWhiteSpace(body))
            return false;

        try
        {
            using var doc = JsonDocument.Parse(body);
            return doc.RootElement.ValueKind == JsonValueKind.Object
                && doc.RootElement.TryGetProperty("type", out var type)
                && string.Equals(type.GetString(), "success", StringComparison.OrdinalIgnoreCase);
        }
        catch (JsonException)
        {
            return false;
        }
    }

    private static string MaskMobile(string mobile) =>
        mobile.Length <= 4 ? "****" : new string('*', mobile.Length - 4) + mobile[^4..];

    [LoggerMessage(Level = LogLevel.Error, Message = "MSG91 OTP delivery failed for {Mobile} (HTTP {StatusCode}): {Body}")]
    private static partial void LogDeliveryFailed(ILogger logger, string mobile, int statusCode, string body);

    [LoggerMessage(Level = LogLevel.Information, Message = "MSG91 accepted OTP for {Mobile}: {Body}")]
    private static partial void LogAccepted(ILogger logger, string mobile, string body);
}
