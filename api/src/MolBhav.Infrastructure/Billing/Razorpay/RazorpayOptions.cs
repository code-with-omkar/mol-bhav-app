using System.ComponentModel.DataAnnotations;

namespace MolBhav.Infrastructure.Billing.Razorpay;

/// <summary>Secrets come from user-secrets or environment variables only (<c>Billing__Razorpay__KeyId</c> …), never appsettings.</summary>
public sealed class RazorpayOptions
{
    public const string Section = "Billing:Razorpay";

    [Required]
    public string KeyId { get; init; } = string.Empty;

    [Required]
    public string KeySecret { get; init; } = string.Empty;

    /// <summary>Required in production. In development, webhook signature verification is skipped; can be any placeholder value.</summary>
    public string WebhookSecret { get; init; } = string.Empty;
}
