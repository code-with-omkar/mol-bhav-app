using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
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

    private const string WebhookUrl = "https://hooks.slack.com/services/T000/B000/XXXX";

    private static readonly OpsAlert Alert = new("Payment webhook parked", [new("Event", "payment.captured (evt_1)")]);

    [Fact]
    public async Task SendAsync_Accepted_PostsTextToTheWebhookAndReturnsTrue()
    {
        var handler = new RecordingHandler(HttpStatusCode.OK, "ok");

        var delivered = await SenderWith(handler).SendAsync(Alert);

        Assert.True(delivered);
        Assert.Equal(HttpMethod.Post, handler.Method);
        Assert.Equal(new Uri(WebhookUrl), handler.Uri);
        using var json = JsonDocument.Parse(handler.Body!);
        Assert.Equal(SlackOpsAlertSender.Format("MolBhav", Alert), json.RootElement.GetProperty("text").GetString());
    }

    [Fact]
    public async Task SendAsync_RejectedBySlack_ReturnsFalseWithoutThrowing()
    {
        var delivered = await SenderWith(new RecordingHandler(HttpStatusCode.NotFound, "no_service")).SendAsync(Alert);

        Assert.False(delivered);
    }

    [Fact]
    public async Task SendAsync_Unreachable_ReturnsFalseWithoutThrowing()
    {
        var delivered = await SenderWith(new ThrowingHandler()).SendAsync(Alert);

        Assert.False(delivered);
    }

    [Fact]
    public void Channel_IsSlack()
    {
        Assert.Equal("slack", SenderWith(new ThrowingHandler()).Channel);
    }

    private static SlackOpsAlertSender SenderWith(HttpMessageHandler handler)
    {
        var factory = Substitute.For<IHttpClientFactory>();
        factory.CreateClient(SlackOpsAlertSender.HttpClientName).Returns(_ => new HttpClient(handler, disposeHandler: false));

        return new SlackOpsAlertSender(
            factory,
            Options.Create(new OpsAlertOptions { SlackWebhookUrl = WebhookUrl, EnvironmentLabel = "MolBhav" }),
            NullLogger<SlackOpsAlertSender>.Instance);
    }

    private sealed class RecordingHandler(HttpStatusCode status, string responseBody) : HttpMessageHandler
    {
        public HttpMethod? Method { get; private set; }

        public Uri? Uri { get; private set; }

        public string? Body { get; private set; }

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Method = request.Method;
            Uri = request.RequestUri;
            Body = request.Content is null ? null : await request.Content.ReadAsStringAsync(cancellationToken);
            return new HttpResponseMessage(status) { Content = new StringContent(responseBody) };
        }
    }

    private sealed class ThrowingHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            throw new HttpRequestException("Name or service not known");
    }
}
