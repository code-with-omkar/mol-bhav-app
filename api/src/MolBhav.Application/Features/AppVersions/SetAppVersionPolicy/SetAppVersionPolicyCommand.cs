using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.AppVersions.SetAppVersionPolicy;

/// <summary>Sets (or clears, with an empty version) the oldest app version allowed to run.</summary>
public sealed record SetAppVersionPolicyCommand(string? MinimumVersion, string? UpdateUrl) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "AppVersion.Set";

    string? IAuditedCommand.AuditTarget => null;

    string IAuditedCommand.AuditSummary => string.IsNullOrWhiteSpace(MinimumVersion)
        ? "Cleared the minimum app version"
        : $"Set the minimum app version to {MinimumVersion.Trim()}";
}
