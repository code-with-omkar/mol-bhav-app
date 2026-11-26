using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Market.Admin.ImportFeedMarkets;
using MolBhav.Application.Features.Market.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.ImportAllFeedMarkets;

internal sealed class ImportAllFeedMarketsCommandHandler(
    IPriceSourceRepository sources,
    ISourceFeedOptionsRepository feedOptions,
    IStateRepository states,
    IMandiRepository mandis,
    IFeedMarketCodes marketCodes) : ICommandHandler<ImportAllFeedMarketsCommand, ImportAllFeedMarketsResponse>
{
    /// <summary>Only Agmarknet's market names are mapped onto mandi codes today.</summary>
    private const string SupportedSourceCode = "agmarknet";

    public async Task<Result<ImportAllFeedMarketsResponse>> Handle(ImportAllFeedMarketsCommand request, CancellationToken cancellationToken)
    {
        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        if (!string.Equals(source.Code, SupportedSourceCode, StringComparison.OrdinalIgnoreCase))
        {
            return Error.Validation("FeedMarkets.SourceNotSupported", "Markets can only be added from the Agmarknet feed.");
        }

        var options = await feedOptions.GetByPriceSourceIdAsync(request.PriceSourceId, cancellationToken);
        if (options is null || options.Markets.Count == 0)
        {
            return Error.Validation(
                "FeedMarkets.NoFeedList",
                "No markets are saved from the feed yet. Run a full pull so the feed's markets are recorded, then try again.");
        }

        var statesCreated = 0;
        var marketsCreated = 0;
        var alreadyInCatalog = 0;
        var other = 0;
        var codesAdded = new HashSet<string>(StringComparer.Ordinal);
        var stateCodesUsed = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        var byState = options.Markets
            .Where(m => !string.IsNullOrWhiteSpace(m.State))
            .GroupBy(m => marketCodes.StateNameFor(m.State), StringComparer.OrdinalIgnoreCase);

        foreach (var group in byState)
        {
            var state = await states.GetByNameAsync(group.Key, cancellationToken);
            if (state is null)
            {
                state = await CreateStateAsync(group.Key, stateCodesUsed, cancellationToken);
                if (state is null)
                {
                    other += group.Count();
                    continue;
                }

                statesCreated++;
            }

            var inState = group.ToList();
            var (created, skipped) = await FeedMarketImporter.ImportAsync(
                state, inState.Select(m => m.Name), inState, mandis, marketCodes, codesAdded, cancellationToken);

            marketsCreated += created;
            alreadyInCatalog += skipped.Count(s => s.Reason == FeedMarketSkipReason.AlreadyInCatalog);
            other += skipped.Count(s => s.Reason != FeedMarketSkipReason.AlreadyInCatalog);
        }

        return new ImportAllFeedMarketsResponse(statesCreated, marketsCreated, alreadyInCatalog, other);
    }

    /// <summary>Adds a state the catalog lacks, with a short unique code; null when no valid code or name can be made.</summary>
    private async Task<State?> CreateStateAsync(string name, HashSet<string> codesUsed, CancellationToken cancellationToken)
    {
        foreach (var candidate in StateCodeCandidates(name))
        {
            if (codesUsed.Contains(candidate) || await states.CodeExistsAsync(candidate, cancellationToken))
            {
                continue;
            }

            var created = State.Create(name, candidate);
            if (created.IsFailure)
            {
                // An invalid name fails for every code; a bad code just moves on to the next candidate.
                if (created.Error.Code.Contains("Name", StringComparison.OrdinalIgnoreCase))
                {
                    return null;
                }

                continue;
            }

            codesUsed.Add(candidate);
            states.Add(created.Value);
            return created.Value;
        }

        return null;
    }

    /// <summary>"Madhya Pradesh" → MP, MADHYAPRAD, MADHYAPR2…; "Goa" → GOA, GOA2…. Codes are 2–10 letters or digits.</summary>
    internal static IEnumerable<string> StateCodeCandidates(string name)
    {
        var words = name
            .Split([' ', '-', '&', ',', '.', '(', ')'], StringSplitOptions.RemoveEmptyEntries)
            .Select(w => new string(w.Where(char.IsLetterOrDigit).ToArray()))
            .Where(w => w.Length > 0)
            .ToArray();
        if (words.Length == 0)
        {
            yield break;
        }

        var joined = string.Concat(words).ToUpperInvariant();
        var initials = words.Length > 1
            ? string.Concat(words.Where(w => !string.Equals(w, "and", StringComparison.OrdinalIgnoreCase)).Select(w => w[0])).ToUpperInvariant()
            : joined[..Math.Min(3, joined.Length)];

        if (initials.Length >= 2)
        {
            yield return initials;
        }

        var longForm = joined[..Math.Min(10, joined.Length)];
        if (longForm.Length >= 2 && longForm != initials)
        {
            yield return longForm;
        }

        var stem = joined[..Math.Min(8, joined.Length)];
        for (var n = 2; n < 100; n++)
        {
            yield return stem + n;
        }
    }
}
