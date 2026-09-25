using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Abstractions.Identity;

public interface IOtpChallengeRepository : IRepository<OtpChallenge, Guid>
{
    /// <summary>Most recently issued challenge for the phone number, whatever its state — used for the resend cooldown and for verification.</summary>
    Task<OtpChallenge?> GetLatestForPhoneAsync(PhoneNumber phoneNumber, CancellationToken cancellationToken = default);
}
