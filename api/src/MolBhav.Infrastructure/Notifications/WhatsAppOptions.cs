namespace MolBhav.Infrastructure.Notifications;

/// <summary>Bound from the <c>Push:WhatsApp</c> section. The access token must come from user-secrets (dev) or an
/// environment variable / Key Vault (prod) — never from appsettings.json.</summary>
public sealed class WhatsAppOptions
{
    public const string SectionName = "Push:WhatsApp";

    /// <summary>Meta System User permanent access token. Required in non-Development environments.</summary>
    public string AccessToken { get; init; } = string.Empty;

    /// <summary>The WhatsApp Business phone number ID from the Meta developer console.</summary>
    public string PhoneNumberId { get; init; } = string.Empty;

    /// <summary>Approved template name (must be pre-approved in Meta Business Manager).</summary>
    public string TemplateName { get; init; } = "molbhav_alert";

    /// <summary>BCP-47 language code of the template variant to use.</summary>
    public string TemplateLanguage { get; init; } = "en";
}
