namespace MolBhav.Infrastructure.Notifications;

public sealed class NotificationDeliveryException(string provider, int statusCode, string responseBody)
    : Exception($"{provider} notification delivery failed (HTTP {statusCode}): {responseBody}")
{
    public string Provider { get; } = provider;
    public int StatusCode { get; } = statusCode;
    public string ResponseBody { get; } = responseBody;
}
