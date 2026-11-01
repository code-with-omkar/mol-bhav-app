using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.AppVersions.SetAppVersionPolicy;

/// <summary>Sets (or clears, with an empty version) the oldest app version allowed to run.</summary>
public sealed record SetAppVersionPolicyCommand(string? MinimumVersion, string? UpdateUrl) : ICommand;
