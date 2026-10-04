using MolBhav.Application.Features.Monetization.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Features.Monetization;

/// <summary>
/// The one place free-tier limits are applied for the current user. Pro users pass every check. Command handlers
/// call it before they add the capped item, inside the command's transaction.
/// </summary>
internal interface IEntitlementService
{
    /// <summary>Fails with the feature's <c>Entitlement.*LimitReached</c> error when the slot capacity is used up.</summary>
    Task<Result> EnsureCanAddAsync(MonetizedFeature slotFeature, CancellationToken cancellationToken);

    /// <summary>Lets a Pro user through; otherwise consumes one report unlock or fails with <c>Report.ProRequired</c>.</summary>
    Task<Result> AuthorizeProReportAsync(CancellationToken cancellationToken);

    /// <summary>Whether a new "watch ads" unlock may start for <paramref name="feature"/>.</summary>
    Task<Result> EnsureCanStartUnlockAsync(MonetizedFeature feature, CancellationToken cancellationToken);

    Task<EntitlementsResponse> GetAsync(CancellationToken cancellationToken);
}
