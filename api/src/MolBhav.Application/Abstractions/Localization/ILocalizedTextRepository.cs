using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.Localization;

namespace MolBhav.Application.Abstractions.Localization;

/// <summary><see cref="IRepository{TAggregate,TId}.GetByIdAsync"/> loads the entry with all its translations.</summary>
public interface ILocalizedTextRepository : IRepository<LocalizedTextEntry, Guid>
{
    Task<bool> KeyExistsAsync(LocalizationKey key, CancellationToken cancellationToken = default);
}
