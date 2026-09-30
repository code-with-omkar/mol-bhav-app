namespace MolBhav.Domain.Support;

/// <summary>Which side of the conversation wrote a <see cref="SupportTicketMessage"/> — drives the chat layout in the app.</summary>
public enum SupportMessageAuthorKind
{
    User = 0,
    Admin = 1,
}
