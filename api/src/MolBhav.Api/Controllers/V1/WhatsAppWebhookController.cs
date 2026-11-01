using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using MolBhav.Application.Features.Notification.RecordWhatsAppDeliveryStatus;
using MolBhav.Infrastructure.Notifications;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// WhatsApp Cloud API webhook: Meta accepts a message with HTTP 200 and reports the real outcome (delivered, read or
/// failed with a code) here. GET answers Meta's one-time URL verification; POST carries status receipts, authenticated
/// by the <c>X-Hub-Signature-256</c> HMAC of the raw body. Any authenticated call gets a 200 so Meta does not retry.
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/webhooks/whatsapp")]
[AllowAnonymous]
[DisableRateLimiting]
[ApiExplorerSettings(IgnoreApi = true)]
public sealed partial class WhatsAppWebhookController(
    ISender sender,
    IOptions<WhatsAppOptions> options,
    ILogger<WhatsAppWebhookController> logger,
    IWebHostEnvironment env) : ControllerBase
{
    private const string SignatureHeader = "X-Hub-Signature-256";
    private const string SignaturePrefix = "sha256=";

    /// <summary>Meta's URL verification: echo <c>hub.challenge</c> when the verify token matches.</summary>
    [HttpGet]
    public IActionResult Verify(
        [FromQuery(Name = "hub.mode")] string? mode,
        [FromQuery(Name = "hub.verify_token")] string? verifyToken,
        [FromQuery(Name = "hub.challenge")] string? challenge)
    {
        var expected = options.Value.WebhookVerifyToken;
        if (mode != "subscribe" || string.IsNullOrEmpty(expected) || string.IsNullOrEmpty(challenge) ||
            !FixedTimeEquals(verifyToken ?? string.Empty, expected))
        {
            LogVerificationRejected(logger);
            return StatusCode(StatusCodes.Status403Forbidden);
        }

        return Content(challenge, "text/plain");
    }

    [HttpPost]
    public async Task<IActionResult> Handle(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body, Encoding.UTF8);
        var rawBody = await reader.ReadToEndAsync(cancellationToken);

        if (!IsAuthentic(rawBody, Request.Headers[SignatureHeader].ToString()))
        {
            LogSignatureRejected(logger);
            return BadRequest();
        }

        foreach (var command in ParseStatuses(rawBody))
        {
            LogStatus(logger, command.ProviderMessageId, command.State, command.Error);
            await sender.Send(command, cancellationToken);
        }

        return Ok();
    }

    private bool IsAuthentic(string rawBody, string header)
    {
        var secret = options.Value.AppSecret;
        if (string.IsNullOrEmpty(secret))
        {
            // Only local development may run without the app secret.
            if (env.IsDevelopment())
            {
                LogDevSkippingSignature(logger);
                return true;
            }

            return false;
        }

        if (!header.StartsWith(SignaturePrefix, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        var expected = Convert.ToHexString(HMACSHA256.HashData(Encoding.UTF8.GetBytes(secret), Encoding.UTF8.GetBytes(rawBody)));
        return FixedTimeEquals(header[SignaturePrefix.Length..].ToUpperInvariant(), expected);
    }

    private static bool FixedTimeEquals(string a, string b) =>
        CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(a), Encoding.UTF8.GetBytes(b));

    /// <summary><c>entry[].changes[].value.statuses[]</c>: delivered/read become Delivered, failed carries Meta's error.</summary>
    private static List<RecordWhatsAppDeliveryStatusCommand> ParseStatuses(string rawBody)
    {
        var commands = new List<RecordWhatsAppDeliveryStatusCommand>();
        try
        {
            using var doc = JsonDocument.Parse(rawBody);
            if (!doc.RootElement.TryGetProperty("entry", out var entries) || entries.ValueKind != JsonValueKind.Array)
            {
                return commands;
            }

            foreach (var entry in entries.EnumerateArray())
            {
                if (!entry.TryGetProperty("changes", out var changes) || changes.ValueKind != JsonValueKind.Array)
                {
                    continue;
                }

                foreach (var change in changes.EnumerateArray())
                {
                    if (!change.TryGetProperty("value", out var value) ||
                        !value.TryGetProperty("statuses", out var statuses) ||
                        statuses.ValueKind != JsonValueKind.Array)
                    {
                        continue;
                    }

                    foreach (var status in statuses.EnumerateArray())
                    {
                        var id = StringOrNull(status, "id");
                        var state = StringOrNull(status, "status");
                        if (id is null || state is null)
                        {
                            continue;
                        }

                        var at = TimestampOrNow(status);
                        switch (state)
                        {
                            case "delivered" or "read":
                                commands.Add(new(id, WhatsAppDeliveryState.Delivered, null, at));
                                break;
                            case "failed":
                                commands.Add(new(id, WhatsAppDeliveryState.Failed, ErrorText(status), at));
                                break;
                        }
                    }
                }
            }
        }
        catch (JsonException)
        {
            // Not Meta's shape: nothing to record.
        }

        return commands;
    }

    private static string ErrorText(JsonElement status)
    {
        if (status.TryGetProperty("errors", out var errors) && errors.ValueKind == JsonValueKind.Array &&
            errors.GetArrayLength() > 0)
        {
            var first = errors[0];
            var code = first.TryGetProperty("code", out var c) ? c.ToString() : "?";
            var title = StringOrNull(first, "title") ?? StringOrNull(first, "message") ?? "unknown error";
            return $"WhatsApp {code}: {title}";
        }

        return "WhatsApp reported a delivery failure.";
    }

    private static DateTimeOffset TimestampOrNow(JsonElement status) =>
        long.TryParse(StringOrNull(status, "timestamp"), NumberStyles.None, CultureInfo.InvariantCulture, out var seconds)
            ? DateTimeOffset.FromUnixTimeSeconds(seconds)
            : DateTimeOffset.UtcNow;

    private static string? StringOrNull(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() : null;

    [LoggerMessage(Level = LogLevel.Warning, Message = "WhatsApp webhook verification rejected: wrong mode or verify token.")]
    private static partial void LogVerificationRejected(ILogger logger);

    [LoggerMessage(Level = LogLevel.Warning, Message = "WhatsApp webhook rejected: missing or invalid signature.")]
    private static partial void LogSignatureRejected(ILogger logger);

    [LoggerMessage(Level = LogLevel.Information, Message = "WhatsApp delivery status for {MessageId}: {State} {Error}")]
    private static partial void LogStatus(ILogger logger, string messageId, WhatsAppDeliveryState state, string? error);

    [LoggerMessage(Level = LogLevel.Information, Message = "Dev mode: skipping WhatsApp webhook signature verification (no AppSecret set).")]
    private static partial void LogDevSkippingSignature(ILogger logger);
}
