using Microsoft.EntityFrameworkCore;
using MolBhav.Application.Abstractions.FeatureSwitches;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Infrastructure.Persistence.Repositories.FeatureSwitches;

internal sealed class FeatureSwitchRepository(MolBhavDbContext dbContext)
    : Repository<FeatureSwitch, Guid>(dbContext), IFeatureSwitchRepository
{
    public Task<FeatureSwitch?> GetByFeatureAsync(AppFeature feature, CancellationToken cancellationToken = default) =>
        Set.SingleOrDefaultAsync(f => f.Feature == feature, cancellationToken);

    public async Task<bool> IsEnabledAsync(AppFeature feature, CancellationToken cancellationToken = default) =>
        !await Set.AsNoTracking().AnyAsync(f => f.Feature == feature && !f.IsEnabled, cancellationToken);

    public async Task<IReadOnlyList<FeatureSwitch>> ListAsync(CancellationToken cancellationToken = default) =>
        await Set.AsNoTracking().ToListAsync(cancellationToken);
}
