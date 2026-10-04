using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Infrastructure.Notifications.OpsAlerts;

namespace MolBhav.UnitTests.Billing;

public sealed class SlackOpsAlertSenderTests
{
    [Fact]
    public void Format_RendersTitleAndDetailLines()
    {
        var alert = new OpsAlert("Payment webhook parked", [new("Event", "payment.captured (evt_1)"), new("Attempts", "10")]);

        var text = SlackOpsAlertSender.Format("MolBhav prod", alert);

        Assert.Equal(
            ":rotating_light: *[MolBhav prod] Payment webhook parked*\n• *Event:* payment.captured (evt_1)\n• *Attempts:* 10",
            text);
    }

    [Fact]
    public void Format_EscapesSlackControlCharacters()
    {
        var alert = new OpsAlert("a <b> & c", [new("Reason", "<!channel> & <https://evil|click>")]);

        var text = SlackOpsAlertSender.Format("env", alert);

        Assert.DoesNotContain("<!channel>", text, StringComparison.Ordinal);
        Assert.Contains("&lt;!channel&gt; &amp; &lt;https://evil|click&gt;", text, StringComparison.Ordinal);
        Assert.Contains("a &lt;b&gt; &amp; c", text, StringComparison.Ordinal);
    }

    [Theory]
    [InlineData(null, true)]
    [InlineData("", true)]
    [InlineData("https://hooks.slack.com/services/T000/B000/XXXX", true)]
    [InlineData("http://hooks.slack.com/services/T000/B000/XXXX", false)]
    [InlineData("hooks.slack.com/services/T000", false)]
    public void HasValidSlackWebhookUrl_AllowsEmptyOrAbsoluteHttps(string? url, bool expected)
    {
        Assert.Equal(expected, new OpsAlertOptions { SlackWebhookUrl = url }.HasValidSlackWebhookUrl);
    }
}
