namespace MolBhav.Domain.Support;

/// <summary>What a <see cref="SupportTicket"/> is about, so the admin queue can be triaged by team.</summary>
public enum SupportTicketCategory
{
    Account = 0,
    Payment = 1,
    Data = 2,
    Other = 3,
}
