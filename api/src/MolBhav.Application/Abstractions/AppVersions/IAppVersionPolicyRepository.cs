using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.AppVersions;

namespace MolBhav.Application.Abstractions.AppVersions;

public interface IAppVersionPolicyRepository : IRepository<AppVersionPolicy, Guid>
{
    /// <summary>The app's one policy, tracked; null until an admin has first saved one.</summary>
    Task<AppVersionPolicy?> GetCurrentAsync(CancellationToken cancellationToken = default);
}
