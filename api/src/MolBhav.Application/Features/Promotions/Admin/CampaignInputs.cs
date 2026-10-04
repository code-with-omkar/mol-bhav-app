using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Promotions;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Promotions.Admin;

/// <summary>The editable part of a campaign, shared by create and update.</summary>
public sealed record CampaignInput(
    string? Name,
    PromotionPlacement? Placement,
    string? Title,
    string? Body,
    string? CtaLabel,
    string? CtaUrl,
    string? ImageUrl,
    DateTimeOffset? StartsAtUtc,
    DateTimeOffset? EndsAtUtc,
    int? Priority,
    int? DailyImpressionCap,
    IReadOnlyList<CampaignTargetInput>? Targets);

/// <summary>Turns a <see cref="CampaignInput"/> into domain values, checking targeted categories and states exist.</summary>
internal sealed class CampaignInputResolver(IProcurementCategoryRepository categories, IStateRepository states)
{
    public async Task<Result<ResolvedCampaignInput>> ResolveAsync(CampaignInput input, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);

        var creative = CampaignCreative.Create(input.Title, input.Body, input.CtaLabel, input.CtaUrl, input.ImageUrl);
        if (creative.IsFailure)
        {
            return Result.Failure<ResolvedCampaignInput>(creative.Error);
        }

        var targets = new List<(string CategoryCode, Guid? StateId)>();
        foreach (var target in input.Targets ?? [])
        {
            var code = ProcurementCategoryCode.Create(target.CategoryCode);
            if (code.IsFailure || !await categories.CodeExistsAsync(code.Value, cancellationToken))
            {
                return Result.Failure<ResolvedCampaignInput>(PromotionErrors.UnknownCategory);
            }

            targets.Add((code.Value.Value, target.StateId));
        }

        foreach (var stateId in targets.Select(t => t.StateId).OfType<Guid>().Distinct())
        {
            if (await states.GetByIdAsync(stateId, cancellationToken) is null)
            {
                return Result.Failure<ResolvedCampaignInput>(PromotionErrors.UnknownState);
            }
        }

        return new ResolvedCampaignInput(
            input.Name,
            input.Placement!.Value,
            creative.Value,
            input.StartsAtUtc!.Value,
            input.EndsAtUtc!.Value,
            input.Priority ?? 0,
            input.DailyImpressionCap,
            targets);
    }
}

internal sealed record ResolvedCampaignInput(
    string? Name,
    PromotionPlacement Placement,
    CampaignCreative Creative,
    DateTimeOffset StartsAtUtc,
    DateTimeOffset EndsAtUtc,
    int Priority,
    int? DailyImpressionCap,
    IReadOnlyCollection<(string CategoryCode, Guid? StateId)> Targets);
