using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.FeatureSwitches.Models;

namespace MolBhav.Application.Features.FeatureSwitches.GetFeatureSwitches;

/// <summary>Every feature with its on/off state; a feature nobody has changed is on.</summary>
public sealed record GetFeatureSwitchesQuery : IQuery<IReadOnlyList<FeatureSwitchResponse>>;
