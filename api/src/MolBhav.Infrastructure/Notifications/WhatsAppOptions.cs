namespace MolBhav.Infrastructure.Notifications;

/// <summary>Bound from the <c>Push:WhatsApp</c> section. The access token must come from user-secrets (dev) or an
/// environment variable / Key Vault (prod) — never from appsettings.json.</summary>
public sealed class WhatsAppOptions
{
    public const string SectionName = "Push:WhatsApp";

    /// <summary>Meta access token (temporary for testing, System User permanent token in production).</summary>
    public string AccessToken { get; init; } = string.Empty;

    /// <summary>The WhatsApp Business phone number ID from the Meta developer console (not the phone number).</summary>
    public string PhoneNumberId { get; init; } = string.Empty;

    /// <summary>Graph API version in the request path, e.g. <c>v25.0</c>.</summary>
    public string ApiVersion { get; init; } = "v25.0";

    /// <summary>Approved template name (business-initiated messages must use an approved template).</summary>
    public string TemplateName { get; init; } = "molbhav_alert";

    /// <summary>Language code of the template variant, exactly as approved (e.g. <c>en</c>, <c>en_US</c>).</summary>
    public string TemplateLanguage { get; init; } = "en";

    /// <summary>
    /// How many <c>{{n}}</c> variables the template body has: 0 (e.g. Meta's <c>hello_world</c> test template),
    /// 1 (<c>{{1}}</c> = "title: body") or 2 (<c>{{1}}</c> = title, <c>{{2}}</c> = body). Sending a different count
    /// than the template defines is rejected by Meta.
    /// </summary>
    public int BodyParameterCount { get; init; } = 1;

    /// <summary>Token Meta echoes back when it verifies the webhook URL (you choose it; any long random string).</summary>
    public string WebhookVerifyToken { get; init; } = string.Empty;

    /// <summary>The Meta app secret, used to check the <c>X-Hub-Signature-256</c> header on webhook calls.</summary>
    public string AppSecret { get; init; } = string.Empty;

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(AccessToken) && !string.IsNullOrWhiteSpace(PhoneNumberId);
}
