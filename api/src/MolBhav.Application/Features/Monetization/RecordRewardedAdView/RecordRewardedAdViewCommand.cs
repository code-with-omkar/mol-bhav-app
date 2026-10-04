using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Monetization.RecordRewardedAdView;

/// <summary>AdMob's server-side-verification callback, passed through untouched so its signature can be checked.</summary>
/// <param name="RawQueryString">The callback's query string without the leading <c>?</c>, exactly as received.</param>
public sealed record RecordRewardedAdViewCommand(string RawQueryString) : ICommand;
