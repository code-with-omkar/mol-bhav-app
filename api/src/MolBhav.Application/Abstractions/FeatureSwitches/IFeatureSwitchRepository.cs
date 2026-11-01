using MolBhav.Application.Abstractions.Data;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Application.Abstractions.FeatureSwitches;

public interface IFeatureSwitchRepository : IRepository<FeatureSwitch, Guid>
{
    /// <summary>The saved switch for a feature, tracked; null while nobody has changed it (the feature is on).</summary>
    Task<FeatureSwitch?> GetByFeatureAsync(AppFeature feature, CancellationToken cancellationToken = default);

    /// <summary>Every saved switch.</summary>
    Task<IReadOnlyList<FeatureSwitch>> ListAsync(CancellationToken cancellationToken = default);
}
