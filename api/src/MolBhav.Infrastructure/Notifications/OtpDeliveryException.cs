namespace MolBhav.Infrastructure.Notifications;

/// <summary>Thrown by <see cref="Msg91OtpSender"/> when the gateway returns a non-2xx response or a body whose type is not "success".</summary>
public sealed class OtpDeliveryException(int statusCode, string responseBody)
    : Exception($"OTP delivery failed (HTTP {statusCode}): {responseBody}")
{
    public int StatusCode { get; } = statusCode;
    public string ResponseBody { get; } = responseBody;
}
