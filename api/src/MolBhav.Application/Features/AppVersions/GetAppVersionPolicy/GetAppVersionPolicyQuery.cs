using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.AppVersions.Models;

namespace MolBhav.Application.Features.AppVersions.GetAppVersionPolicy;

/// <summary>The oldest app version still allowed, and where to update from. No minimum until an admin sets one.</summary>
public sealed record GetAppVersionPolicyQuery : IQuery<AppVersionPolicyResponse>;
