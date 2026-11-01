using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Application.Features.FeatureSwitches.SetFeatureSwitch;

/// <summary>Turns a feature on or off for every user.</summary>
public sealed record SetFeatureSwitchCommand(AppFeature Feature, bool Enabled) : ICommand;
