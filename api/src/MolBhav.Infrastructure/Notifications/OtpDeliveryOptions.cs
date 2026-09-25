namespace MolBhav.Infrastructure.Notifications;

/// <summary>Bound from the <c>OtpDelivery</c> section.</summary>
public sealed class OtpDeliveryOptions
{
    public const string SectionName = "OtpDelivery";

    /// <summary>
    /// <c>Log</c> writes the code to the application log (local development only — the app refuses to start with it
    /// outside Development). Real SMS/WhatsApp providers are added as further values when a gateway is chosen.
    /// </summary>
    public string Provider { get; set; } = OtpDeliveryProviders.Log;
}

public static class OtpDeliveryProviders
{
    public const string Log = "Log";
}
