using System.Text;
using Asp.Versioning;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Features.Billing.Webhook;

namespace MolBhav.Api.Controllers.V1;

/// <summary>
/// Razorpay webhooks. The HMAC of the raw body (buffered for this path in Program.cs) is the only authentication,
/// so it is checked before anything else and there is no path that skips it outside Development.
/// <para>
/// An authenticated event is only recorded in the webhook inbox here; the inbox processor applies it asynchronously
/// (with retries), so the 200 goes back well inside Razorpay's 5 s timeout. Redeliveries also get a 200. A 400 means
/// "not from Razorpay" (bad signature or no event id); a 5xx (database down) makes Razorpay redeliver.
/// </para>
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
    private const string EventIdHeader = "x-razorpay-event-id";

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

        // A missing event id fails validation (400 via the global exception handler).
        var result = await sender.Send(
            new ReceiveRazorpayWebhookCommand(Request.Headers[EventIdHeader].ToString(), rawBody), cancellationToken);

        return result.IsSuccess ? Ok() : BadRequest();
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Razorpay webhook rejected: missing or invalid signature.")]
    private static partial void LogRejected(ILogger logger);

    [LoggerMessage(Level = LogLevel.Information, Message = "Dev mode: skipping webhook signature verification.")]
    private static partial void LogDevModeSkippingVerification(ILogger logger);
}
