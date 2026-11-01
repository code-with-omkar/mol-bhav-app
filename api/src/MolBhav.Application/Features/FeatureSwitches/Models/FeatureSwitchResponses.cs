using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Application.Features.FeatureSwitches.Models;

/// <summary>One feature and whether users can use it.</summary>
public sealed record FeatureSwitchResponse(AppFeature Feature, bool IsEnabled);

/// <param name="Enabled">Whether the feature is on for users.</param>
public sealed record SetFeatureSwitchRequest(bool Enabled);
