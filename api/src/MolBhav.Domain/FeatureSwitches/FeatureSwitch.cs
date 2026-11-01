using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.FeatureSwitches;

/// <summary>A part of the app an admin can switch off for every user without shipping a new build.</summary>
public enum AppFeature
{
    /// <summary>Every in-content ad slot (sponsored cards and AdMob native ads).</summary>
    Ads = 0,

    /// <summary>The Reports screen and the shortcuts to it.</summary>
    Reports = 1,

    /// <summary>The cost estimator and the shortcuts to it.</summary>
    CostEstimator = 2,
}

/// <summary>
/// One feature's on/off state. A feature with no row is on, so a new feature ships enabled and a row appears only the
/// first time an admin changes it.
/// </summary>
public sealed class FeatureSwitch : AggregateRoot<Guid>, IAuditableEntity
{
    private FeatureSwitch(Guid id, AppFeature feature, bool isEnabled)
        : base(id)
    {
        Feature = feature;
        IsEnabled = isEnabled;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private FeatureSwitch()
    {
    }

    public AppFeature Feature { get; private set; }

    public bool IsEnabled { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<FeatureSwitch> Create(AppFeature feature, bool isEnabled)
    {
        if (!Enum.IsDefined(feature))
        {
            return Error.Validation("FeatureSwitch.FeatureInvalid", "Unknown feature.");
        }

        return new FeatureSwitch(Guid.CreateVersion7(), feature, isEnabled);
    }

    public void SetEnabled(bool isEnabled) => IsEnabled = isEnabled;
}
