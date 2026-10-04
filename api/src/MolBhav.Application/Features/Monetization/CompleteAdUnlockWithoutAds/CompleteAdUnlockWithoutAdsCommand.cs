using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Monetization.Models;

namespace MolBhav.Application.Features.Monetization.CompleteAdUnlockWithoutAds;

/// <summary>Sent when no rewarded ad could be loaded, so a user is not blocked by missing ad inventory.</summary>
public sealed record CompleteAdUnlockWithoutAdsCommand(Guid SessionId) : ICommand<AdUnlockSessionResponse>;
