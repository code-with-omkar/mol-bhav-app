namespace MolBhav.Application.Abstractions.Support;

/// <summary>
/// The support channels the app offers before a ticket is raised (WhatsApp, phone, email). Configuration, not data —
/// the implementation reads the <c>Support</c> section, validated at startup.
/// </summary>
public interface ISupportContactProvider
{
    SupportContact GetContact();
}

/// <summary>E.164 WhatsApp number (no <c>+</c>, as <c>wa.me</c> expects), dialable phone, and support mailbox.</summary>
public sealed record SupportContact(string WhatsAppNumber, string Phone, string Email);
