using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Abstractions.Identity;

public interface IRefreshTokenRepository : IRepository<RefreshTokenGrant, Guid>
{
    Task<RefreshTokenGrant?> GetByTokenHashAsync(string tokenHash, CancellationToken cancellationToken = default);

    /// <summary>Every still-active (not yet revoked) grant in a rotation family — used to shut the family down on reuse detection.</summary>
    Task<IReadOnlyCollection<RefreshTokenGrant>> GetActiveFamilyAsync(Guid familyId, CancellationToken cancellationToken = default);
}
