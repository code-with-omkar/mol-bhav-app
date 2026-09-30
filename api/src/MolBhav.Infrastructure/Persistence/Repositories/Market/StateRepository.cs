using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Domain.Market;

namespace MolBhav.Infrastructure.Persistence.Repositories.Market;

internal sealed class StateRepository(MolBhavDbContext dbContext) : Repository<State, Guid>(dbContext), IStateRepository
{
    /// <summary>Loads the whole aggregate: districts.</summary>
    public override Task<State?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Set.Include(s => s.Districts)
            .AsSplitQuery()
            .SingleOrDefaultAsync(s => s.Id == id, cancellationToken);

    public Task<bool> NameExistsAsync(string name, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(s => s.Name == name, cancellationToken);

    public Task<bool> CodeExistsAsync(string code, CancellationToken cancellationToken = default) =>
        Set.AnyAsync(s => s.Code == code, cancellationToken);

    public Task<bool> DistrictExistsAsync(Guid districtId, CancellationToken cancellationToken = default) =>
        DbContext.Set<District>().AnyAsync(d => d.Id == districtId, cancellationToken);
}
