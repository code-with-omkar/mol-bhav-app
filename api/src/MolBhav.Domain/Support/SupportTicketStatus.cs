namespace MolBhav.Domain.Support;

/// <summary>
/// Lifecycle of a <see cref="SupportTicket"/>. Only an admin sets it explicitly; the aggregate also moves it
/// itself on a reply (<see cref="Open"/> → <see cref="InProgress"/> when support answers,
/// <see cref="Resolved"/> → <see cref="Open"/> when the user comes back). <see cref="Closed"/> is terminal.
/// </summary>
public enum SupportTicketStatus
{
    Open = 0,
    InProgress = 1,
    Resolved = 2,
    Closed = 3,
}
