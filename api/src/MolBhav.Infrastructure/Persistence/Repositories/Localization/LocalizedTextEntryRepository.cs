using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Domain.Localization;

namespace MolBhav.Infrastructure.Persistence.Repositories.Localization;

internal sealed class LocalizedTextEntryRepository(MolBhavDbContext dbContext)
    : Repository<LocalizedTextEntry, Guid>(dbContext), ILocalizedTextRepository
{
    /// <summary>Owned translations are always included by EF, so the base <c>FindAsync</c> already loads the whole aggregate.</summary>
    public Task<bool> KeyExistsAsync(LocalizationKey key, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(e => e.Key == key, cancellationToken);
}
