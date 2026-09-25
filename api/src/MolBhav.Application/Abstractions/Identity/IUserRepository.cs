using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Abstractions.Identity;

public interface IUserRepository : IRepository<User, Guid>
{
    Task<User?> GetByPhoneNumberAsync(PhoneNumber phoneNumber, CancellationToken cancellationToken = default);
}
