using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.AppNotices;

namespace MolBhav.Application.Abstractions.AppNotices;

public interface IAppNoticeRepository : IRepository<AppNotice, Guid>
{
    /// <summary>The app's one notice, tracked; null until an admin has first saved one.</summary>
    Task<AppNotice?> GetCurrentAsync(CancellationToken cancellationToken = default);
}
