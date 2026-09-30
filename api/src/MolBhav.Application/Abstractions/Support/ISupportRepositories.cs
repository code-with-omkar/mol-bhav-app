using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Support;

namespace MolBhav.Application.Abstractions.Support;

public interface ISupportTicketRepository : IRepository<SupportTicket, Guid>
{
}
