namespace MolBhav.Application.Abstractions.Notifications;

/// <summary>
/// Alerts for the people running MolBhav (not end users): things that need a human soon, such as a parked payment
/// webhook. Sending never throws — an alert channel outage must not break the work that raised the alert.
/// </summary>
public interface IOpsAlertSender
{
    /// <summary>Where alerts go: <c>slack</c>, or <c>log</c> when no channel is configured.</summary>
    string Channel { get; }

    /// <returns><c>true</c> if the channel accepted the alert; <c>false</c> if delivery failed (already logged).</returns>
    Task<bool> SendAsync(OpsAlert alert, CancellationToken cancellationToken = default);
}

/// <param name="Title">One line, e.g. "Payment webhook parked".</param>
/// <param name="Details">Key facts as label/value pairs (ids, amounts, error); never secrets or full payloads.</param>
public sealed record OpsAlert(string Title, IReadOnlyList<KeyValuePair<string, string>> Details);
