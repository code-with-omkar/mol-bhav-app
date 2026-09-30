namespace MolBhav.Infrastructure.Notifications;

/// <summary>Bound from the <c>OtpDelivery:Msg91</c> section.</summary>
public sealed class Msg91Options
{
    public const string SectionName = "OtpDelivery:Msg91";

    public string AuthKey { get; init; } = string.Empty;
    public string TemplateId { get; init; } = string.Empty;

    /// <summary>Optional sender/header ID registered with MSG91.</summary>
    public string SenderIdOrFrom { get; init; } = "MOLBHV";

    /// <summary>Country dial prefix prepended to the national number.</summary>
    public string CountryPrefix { get; init; } = "91";
}
