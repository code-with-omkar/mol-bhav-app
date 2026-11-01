using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Ingestion;

/// <summary>
/// What an adapter should ask its source for: any mix of states, commodities and markets, each spelled exactly as the
/// source spells it (data.gov.in filters server-side on exact names). An empty list means "all"; <see cref="Empty"/>
/// pulls everything. Names are trimmed and de-duplicated (case-insensitive), so equal filters compare equal.
/// </summary>
public sealed record IngestionFilter
{
    public const int MaxNamesPerList = 20;
    public const int MaxNameLength = 100;

    /// <summary>The source is queried once per state × commodity × market combination; more than this is refused.</summary>
    public const int MaxCombinations = 30;

    public static readonly IngestionFilter Empty = new();

    private IngestionFilter()
    {
    }

    public IReadOnlyList<string> States { get; private init; } = [];

    public IReadOnlyList<string> Commodities { get; private init; } = [];

    public IReadOnlyList<string> Markets { get; private init; } = [];

    public bool IsEmpty => States.Count == 0 && Commodities.Count == 0 && Markets.Count == 0;

    /// <summary>How many separate requests per page-run the source will get (an empty list counts as one "all").</summary>
    public int Combinations => Math.Max(1, States.Count) * Math.Max(1, Commodities.Count) * Math.Max(1, Markets.Count);

    public static Result<IngestionFilter> Create(
        IEnumerable<string>? states, IEnumerable<string>? commodities, IEnumerable<string>? markets)
    {
        var filter = new IngestionFilter
        {
            States = Normalize(states),
            Commodities = Normalize(commodities),
            Markets = Normalize(markets),
        };

        foreach (var (label, names) in new[] { ("states", filter.States), ("commodities", filter.Commodities), ("markets", filter.Markets) })
        {
            if (names.Count > MaxNamesPerList)
            {
                return Error.Validation("IngestionFilter.TooManyNames", $"At most {MaxNamesPerList} {label} per filter.");
            }

            if (names.Any(n => n.Length > MaxNameLength))
            {
                return Error.Validation("IngestionFilter.NameTooLong", $"A {label} name cannot exceed {MaxNameLength} characters.");
            }
        }

        return filter.Combinations > MaxCombinations
            ? Error.Validation(
                "IngestionFilter.TooBroad",
                $"State × commodity × market combinations ({filter.Combinations}) exceed {MaxCombinations}; narrow the filter or pull everything.")
            : filter;
    }

    /// <summary>Equal when each list holds the same names (the lists are already normalised).</summary>
    public bool Equals(IngestionFilter? other) =>
        other is not null
        && States.SequenceEqual(other.States, StringComparer.OrdinalIgnoreCase)
        && Commodities.SequenceEqual(other.Commodities, StringComparer.OrdinalIgnoreCase)
        && Markets.SequenceEqual(other.Markets, StringComparer.OrdinalIgnoreCase);

    public override int GetHashCode() => HashCode.Combine(States.Count, Commodities.Count, Markets.Count);

    private static string[] Normalize(IEnumerable<string>? names) =>
        (names ?? [])
            .Select(n => n?.Trim() ?? string.Empty)
            .Where(n => n.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
}
