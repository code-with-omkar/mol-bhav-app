using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Persistence.Repositories.Identity;

/// <summary>Owned profile columns and the categories collection are loaded automatically with the aggregate (owned types are always included).</summary>
internal sealed class UserRepository(MolBhavDbContext dbContext) : Repository<User, Guid>(dbContext), IUserRepository
{
    public override Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Set.SingleOrDefaultAsync(u => u.Id == id, cancellationToken);

    public Task<User?> GetByPhoneNumberAsync(PhoneNumber phoneNumber, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(phoneNumber);

        return Set.SingleOrDefaultAsync(u => u.PhoneNumber == phoneNumber, cancellationToken);
    }

    public Task<User?> GetByExternalLoginAsync(
        ExternalLoginProvider provider, string subject, CancellationToken cancellationToken = default) =>
        Set.SingleOrDefaultAsync(
            u => u.ExternalLogins.Any(l => l.Provider == provider && l.Subject == subject),
            cancellationToken);
}
