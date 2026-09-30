using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Support;

namespace MolBhav.Infrastructure.Support;

/// <summary>Serves the configured <see cref="SupportOptions"/> as the app-facing contact card.</summary>
internal sealed class ConfiguredSupportContactProvider(IOptions<SupportOptions> options) : ISupportContactProvider
{
    public SupportContact GetContact()
    {
        var settings = options.Value;
        return new SupportContact(
            // The app builds a wa.me link straight from this, so it leaves here as bare digits
            // however it was written in configuration.
            SupportOptions.NormaliseWhatsAppNumber(settings.WhatsAppNumber),
            settings.Phone,
            settings.Email);
    }
}
