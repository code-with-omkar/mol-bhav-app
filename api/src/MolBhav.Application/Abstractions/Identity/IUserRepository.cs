using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Abstractions.Identity;

public interface IUserRepository : IRepository<User, Guid>
{
    Task<User?> GetByPhoneNumberAsync(PhoneNumber phoneNumber, CancellationToken cancellationToken = default);

    /// <summary>The live user a third-party account (e.g. a Google <c>sub</c>) is linked to; null when none.</summary>
    Task<User?> GetByExternalLoginAsync(ExternalLoginProvider provider, string subject, CancellationToken cancellationToken = default);
}
