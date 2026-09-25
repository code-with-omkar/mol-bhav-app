using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Infrastructure.Persistence.Repositories.Identity;

internal sealed class OtpChallengeRepository(MolBhavDbContext dbContext)
    : Repository<OtpChallenge, Guid>(dbContext), IOtpChallengeRepository
{
    /// <summary>Served by the (phone_number, id DESC) index — UUIDv7 ids sort by issue time.</summary>
    public Task<OtpChallenge?> GetLatestForPhoneAsync(PhoneNumber phoneNumber, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(phoneNumber);

        return Set
            .Where(c => c.PhoneNumber == phoneNumber)
            .OrderByDescending(c => c.Id)
            .FirstOrDefaultAsync(cancellationToken);
    }
}
