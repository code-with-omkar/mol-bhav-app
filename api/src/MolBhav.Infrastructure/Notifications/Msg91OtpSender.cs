using System.Net.Http.Json;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Notifications;

/// <summary>
/// Delivers an OTP via the MSG91 OTP API v5. Registered only when <c>OtpDelivery:Provider</c> is <c>Msg91</c>
/// and <c>OtpDelivery:Msg91:AuthKey</c> is non-empty. Falls back to <see cref="LoggingOtpSender"/> in Development
/// when the key is absent (see <c>DependencyInjection.AddIdentityModule</c>).
/// </summary>
internal sealed class Msg91OtpSender(
    IHttpClientFactory httpClientFactory,
    IOptions<Msg91Options> options) : IOtpSender
{
    public const string HttpClientName = "msg91";

    private static readonly Uri OtpEndpoint = new("api/v5/otp", UriKind.Relative);

    public async Task SendAsync(PhoneNumber phoneNumber, string code, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(phoneNumber);
        ArgumentException.ThrowIfNullOrWhiteSpace(code);

        var opts = options.Value;

        // PhoneNumber.Value is E.164 (+91XXXXXXXXXX). MSG91 expects the number without the leading '+'.
        var mobile = phoneNumber.Value.TrimStart('+');

        var payload = new
        {
            template_id = opts.TemplateId,
            mobile,
            authkey = opts.AuthKey,
            otp = code,
        };

        var client = httpClientFactory.CreateClient(HttpClientName);
        using var response = await client.PostAsJsonAsync(OtpEndpoint, payload, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new OtpDeliveryException((int)response.StatusCode, body);
        }
    }
}
