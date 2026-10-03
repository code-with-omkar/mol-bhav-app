using System.Text;
using System.Text.Json;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Common.Exceptions;
using MolBhav.Application.Features.Billing.Webhook;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Razorpay webhooks. The HMAC of the raw body (buffered for this path in Program.cs) is the only authentication,
/// so it is checked before any parsing and there is no path that skips it. Any authenticated event gets a 200, including
/// replays and unknown orders, so Razorpay does not retry forever; a 400 means "not from Razorpay".
/// </summary>
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/billing/webhook")]
[AllowAnonymous]
[DisableRateLimiting]
[ApiExplorerSettings(IgnoreApi = true)]
public sealed partial class BillingWebhookController(
    ISender sender,
    IPaymentGateway paymentGateway,
    ILogger<BillingWebhookController> logger,
    IWebHostEnvironment env) : ControllerBase
{
    private const string SignatureHeader = "X-Razorpay-Signature";

    [HttpPost]
    public async Task<IActionResult> Handle(CancellationToken cancellationToken)
    {
        Request.Body.Position = 0;
        using var reader = new StreamReader(Request.Body, Encoding.UTF8, leaveOpen: true);
        var rawBody = await reader.ReadToEndAsync(cancellationToken);

        // Skip signature verification in Development mode to test without webhook secret
        if (!env.IsDevelopment())
        {
            if (!paymentGateway.VerifyWebhookSignature(rawBody, Request.Headers[SignatureHeader].ToString()))
            {
                LogRejected(logger);
                return BadRequest();
            }
        }
        else
        {
            LogDevModeSkippingVerification(logger);
        }

        if (!TryParse(rawBody, out var command))
        {
            LogUnparseable(logger);
            return Ok();
        }

        try
        {
            await sender.Send(command, cancellationToken);
        }
        catch (Exception ex) when (ex is ConcurrencyConflictException or UniqueConstraintViolationException)
        {
            // The client activate call (or a parallel delivery) committed the same activation first.
            LogAlreadyProcessed(logger, command.OrderId);
        }

        return Ok();
    }

    /// <summary>Order and payment ids from <c>payload.payment.entity</c>, falling back to <c>payload.order.entity.id</c>.</summary>
    private static bool TryParse(string rawBody, out HandleRazorpayWebhookCommand command)
    {
        command = null!;
        try
        {
            using var doc = JsonDocument.Parse(rawBody);
            var root = doc.RootElement;
            if (!root.TryGetProperty("event", out var eventProp) || eventProp.GetString() is not { } eventType)
            {
                return false;
            }

            string? orderId = null, paymentId = null;
            if (root.TryGetProperty("payload", out var payload))
            {
                if (payload.TryGetProperty("payment", out var payment) && payment.TryGetProperty("entity", out var p))
                {
                    orderId = StringOrNull(p, "order_id");
                    paymentId = StringOrNull(p, "id");
                }

                if (orderId is null && payload.TryGetProperty("order", out var order) && order.TryGetProperty("entity", out var o))
                {
                    orderId = StringOrNull(o, "id");
                }
            }

            command = new HandleRazorpayWebhookCommand(eventType, orderId, paymentId);
            return true;
        }
        catch (JsonException)
        {
            return false;
        }
    }

    private static string? StringOrNull(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() : null;

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay webhook rejected: missing or invalid signature.")]
    private static partial void LogRejected(ILogger logger);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay webhook with a valid signature but no readable event; ignored.")]
    private static partial void LogUnparseable(ILogger logger);

    [LoggerMessage(Level = LogLevel.Information, Message = "Razorpay webhook for order {OrderId} was already processed.")]
    private static partial void LogAlreadyProcessed(ILogger logger, string? orderId);

    [LoggerMessage(Level = LogLevel.Information, Message = "Dev mode: skipping webhook signature verification.")]
    private static partial void LogDevModeSkippingVerification(ILogger logger);
}
