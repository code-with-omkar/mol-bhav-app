using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.ImportFeedMarkets;

/// <summary>
/// Turns feed markets of one state into mandis (and their districts). Shared by "add the markets I picked" and "add every
/// market in the feed" so both apply the same rules.
/// </summary>
internal static class FeedMarketImporter
{
    /// <param name="codesAdded">
    /// Codes added so far in this unit of work. Pass the same set for every state of one request: two states can hold a
    /// market of the same name, and the database cannot see mandis that are not saved yet.
    /// </param>
    public static async Task<(int Created, List<SkippedFeedMarket> Skipped)> ImportAsync(
        State state,
        IEnumerable<string> names,
        IReadOnlyList<FeedMarket> inState,
        IMandiRepository mandis,
        IFeedMarketCodes marketCodes,
        ISet<string> codesAdded,
        CancellationToken cancellationToken)
    {
        var created = 0;
        var skipped = new List<SkippedFeedMarket>();

        foreach (var name in names.Select(n => n.Trim()).Where(n => n.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase))
        {
            var feed = inState.FirstOrDefault(m => string.Equals(m.Name, name, StringComparison.OrdinalIgnoreCase));
            if (feed is null)
            {
                skipped.Add(new SkippedFeedMarket(name, FeedMarketSkipReason.NotInFeed));
                continue;
            }

            var code = MarketCode.Create(marketCodes.CodeFor(feed.Name));
            if (code.IsFailure)
            {
                skipped.Add(new SkippedFeedMarket(feed.Name, FeedMarketSkipReason.CodeInvalid));
                continue;
            }

            // Two feed names can resolve to one code (spelling variants); the first one wins.
            if (codesAdded.Contains(code.Value.Value) || await mandis.CodeExistsAsync(code.Value, cancellationToken))
            {
                skipped.Add(new SkippedFeedMarket(feed.Name, FeedMarketSkipReason.AlreadyInCatalog));
                continue;
            }

            if (string.IsNullOrWhiteSpace(feed.District))
            {
                skipped.Add(new SkippedFeedMarket(feed.Name, FeedMarketSkipReason.DistrictUnknown));
                continue;
            }

            var districtName = feed.District.Trim();
            var district = state.Districts.FirstOrDefault(d => string.Equals(d.Name, districtName, StringComparison.OrdinalIgnoreCase));
            if (district is null)
            {
                var added = state.AddDistrict(districtName);
                if (added.IsFailure)
                {
                    skipped.Add(new SkippedFeedMarket(feed.Name, FeedMarketSkipReason.NameInvalid));
                    continue;
                }

                district = added.Value;
            }

            var mandi = Mandi.Create(code.Value, district.Id, feed.Name);
            if (mandi.IsFailure)
            {
                skipped.Add(new SkippedFeedMarket(feed.Name, FeedMarketSkipReason.NameInvalid));
                continue;
            }

            mandis.Add(mandi.Value);
            codesAdded.Add(code.Value.Value);
            created++;
        }

        return (created, skipped);
    }
}
