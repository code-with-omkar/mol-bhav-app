using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Ingestion;

/// <summary>A market as the source spells it, with the state it sits in (so the app can offer markets per state).</summary>
public sealed record FeedMarket(string Name, string State);

/// <summary>
/// The names a source's feed actually contains — its states (derived from the markets), markets and commodities, spelled
/// exactly as the source spells them. Refreshed by every <em>full</em> (unfiltered) pull, so the admin app can offer them
/// as dropdowns for a filtered manual run without any list being hard-coded. One row per source, replaced wholesale.
/// </summary>
public sealed class SourceFeedOptions : AggregateRoot<Guid>, IAuditableEntity
{
    private SourceFeedOptions(Guid id, Guid priceSourceId)
        : base(id)
    {
        PriceSourceId = priceSourceId;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private SourceFeedOptions()
    {
    }

    public Guid PriceSourceId { get; private set; }

    public IReadOnlyList<string> Commodities { get; private set; } = [];

    public IReadOnlyList<FeedMarket> Markets { get; private set; } = [];

    /// <summary>The full pull these names came from.</summary>
    public DateTimeOffset RefreshedAtUtc { get; private set; }

    /// <summary>Every state that has at least one market, A–Z.</summary>
    public IReadOnlyList<string> States =>
        Markets.Select(m => m.State).Distinct(StringComparer.OrdinalIgnoreCase).Order(StringComparer.OrdinalIgnoreCase).ToArray();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<SourceFeedOptions> Create(
        Guid priceSourceId, IEnumerable<string> commodities, IEnumerable<FeedMarket> markets, DateTimeOffset nowUtc)
    {
        if (priceSourceId == Guid.Empty)
        {
            return Error.Validation("SourceFeedOptions.PriceSourceRequired", "Price source is required.");
        }

        var options = new SourceFeedOptions(Guid.CreateVersion7(), priceSourceId);
        options.Replace(commodities, markets, nowUtc);
        return options;
    }

    /// <summary>Replaces everything with what the latest full pull saw (blanks dropped, names de-duplicated and sorted).</summary>
    public void Replace(IEnumerable<string> commodities, IEnumerable<FeedMarket> markets, DateTimeOffset nowUtc)
    {
        Commodities = commodities
            .Select(c => c?.Trim() ?? string.Empty)
            .Where(c => c.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Order(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        Markets = markets
            .Select(m => new FeedMarket(m.Name?.Trim() ?? string.Empty, m.State?.Trim() ?? string.Empty))
            .Where(m => m.Name.Length > 0 && m.State.Length > 0)
            .DistinctBy(m => (m.State.ToUpperInvariant(), m.Name.ToUpperInvariant()))
            .OrderBy(m => m.State, StringComparer.OrdinalIgnoreCase)
            .ThenBy(m => m.Name, StringComparer.OrdinalIgnoreCase)
            .ToArray();

        RefreshedAtUtc = nowUtc;
    }
}
