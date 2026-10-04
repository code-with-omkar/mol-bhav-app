using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Promotions;

/// <summary>The creative a sponsored card shows. Plain text the app renders in its own card style.</summary>
public sealed record CampaignCreative(string Title, string Body, string CtaLabel, Uri CtaUrl, Uri? ImageUrl)
{
    public const int TitleMaxLength = 60;
    public const int BodyMaxLength = 140;
    public const int CtaLabelMaxLength = 24;
    public const int UrlMaxLength = 500;

    public static Result<CampaignCreative> Create(string? title, string? body, string? ctaLabel, string? ctaUrl, string? imageUrl)
    {
        var t = title?.Trim() ?? string.Empty;
        if (t.Length is 0 or > TitleMaxLength)
        {
            return Error.Validation("Campaign.TitleInvalid", $"Title is required and at most {TitleMaxLength} characters.");
        }

        var b = body?.Trim() ?? string.Empty;
        if (b.Length is 0 or > BodyMaxLength)
        {
            return Error.Validation("Campaign.BodyInvalid", $"Body is required and at most {BodyMaxLength} characters.");
        }

        var c = ctaLabel?.Trim() ?? string.Empty;
        if (c.Length is 0 or > CtaLabelMaxLength)
        {
            return Error.Validation("Campaign.CtaLabelInvalid", $"Button label is required and at most {CtaLabelMaxLength} characters.");
        }

        // https only: the app opens these outside itself, so no http, javascript: or intent: schemes.
        if (!TryHttps(ctaUrl, out var cta))
        {
            return Error.Validation("Campaign.CtaUrlInvalid", "Button link must be an https URL.");
        }

        Uri? image = null;
        if (!string.IsNullOrWhiteSpace(imageUrl) && !TryHttps(imageUrl, out image))
        {
            return Error.Validation("Campaign.ImageUrlInvalid", "Image must be an https URL.");
        }

        return new CampaignCreative(t, b, c, cta!, image);
    }

    private static bool TryHttps(string? value, out Uri? uri)
    {
        uri = null;
        // The stored form (AbsoluteUri, punycoded and escaped) is what must fit the column, not the raw input.
        return value is { Length: > 0 }
            && Uri.TryCreate(value.Trim(), UriKind.Absolute, out uri)
            && uri.Scheme == Uri.UriSchemeHttps
            && !string.IsNullOrEmpty(uri.Host)
            && uri.AbsoluteUri.Length <= UrlMaxLength;
    }
}

/// <summary>
/// One sold sponsorship: a creative, where it shows, who it targets and when. Served to a free user whose categories
/// (and state, when targeted) match, while <see cref="CampaignStatus.Active"/> and inside its schedule — see
/// <see cref="IsServableAt"/>; daily caps are checked against delivery counts by the read side.
/// </summary>
public sealed class Campaign : AggregateRoot<Guid>, IAuditableEntity
{
    public const int NameMaxLength = 120;
    public const int MaxPriority = 100;
    public const int MaxTargets = 100;

    private readonly List<CampaignTarget> _targets = [];

    private Campaign(Guid id, Guid advertiserId, string name, PromotionPlacement placement)
        : base(id)
    {
        AdvertiserId = advertiserId;
        Name = name;
        Placement = placement;
        Status = CampaignStatus.Draft;
        Title = string.Empty;
        Body = string.Empty;
        CtaLabel = string.Empty;
        CtaUrl = string.Empty;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Campaign()
    {
        Name = string.Empty;
        Title = string.Empty;
        Body = string.Empty;
        CtaLabel = string.Empty;
        CtaUrl = string.Empty;
    }

    public Guid AdvertiserId { get; private set; }

    /// <summary>Internal name for the admin list, e.g. "UltraTech – Pune – Oct".</summary>
    public string Name { get; private set; }

    public PromotionPlacement Placement { get; private set; }

    public CampaignStatus Status { get; private set; }

    public DateTimeOffset StartsAtUtc { get; private set; }

    public DateTimeOffset EndsAtUtc { get; private set; }

    /// <summary>Higher wins when several campaigns match one user and slot (0–100).</summary>
    public int Priority { get; private set; }

    /// <summary>Stops serving for the rest of the IST day once reached; <c>null</c> = no cap.</summary>
    public int? DailyImpressionCap { get; private set; }

    public string Title { get; private set; }

    public string Body { get; private set; }

    public string CtaLabel { get; private set; }

    public string CtaUrl { get; private set; }

    public string? ImageUrl { get; private set; }

    public IReadOnlyCollection<CampaignTarget> Targets => _targets.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<Campaign> Create(
        Guid advertiserId,
        string? name,
        PromotionPlacement placement,
        CampaignCreative creative,
        DateTimeOffset startsAtUtc,
        DateTimeOffset endsAtUtc,
        int priority,
        int? dailyImpressionCap,
        IReadOnlyCollection<(string CategoryCode, Guid? StateId)> targets)
    {
        if (advertiserId == Guid.Empty)
        {
            return Error.Validation("Campaign.AdvertiserRequired", "Advertiser is required.");
        }

        var campaign = new Campaign(Guid.CreateVersion7(), advertiserId, string.Empty, placement);
        var updated = campaign.Update(name, placement, creative, startsAtUtc, endsAtUtc, priority, dailyImpressionCap, targets);
        return updated.IsFailure ? Result.Failure<Campaign>(updated.Error) : campaign;
    }

    /// <summary>Replaces everything editable. Allowed in any status but <see cref="CampaignStatus.Ended"/>.</summary>
    public Result Update(
        string? name,
        PromotionPlacement placement,
        CampaignCreative creative,
        DateTimeOffset startsAtUtc,
        DateTimeOffset endsAtUtc,
        int priority,
        int? dailyImpressionCap,
        IReadOnlyCollection<(string CategoryCode, Guid? StateId)> targets)
    {
        ArgumentNullException.ThrowIfNull(creative);
        ArgumentNullException.ThrowIfNull(targets);

        if (Status == CampaignStatus.Ended)
        {
            return Error.BusinessRule("Campaign.Ended", "An ended campaign cannot be changed.");
        }

        var n = name?.Trim() ?? string.Empty;
        if (n.Length is 0 or > NameMaxLength)
        {
            return Error.Validation("Campaign.NameInvalid", $"Name is required and at most {NameMaxLength} characters.");
        }

        if (!Enum.IsDefined(placement))
        {
            return Error.Validation("Campaign.PlacementInvalid", "Unknown placement.");
        }

        if (endsAtUtc <= startsAtUtc)
        {
            return Error.Validation("Campaign.ScheduleInvalid", "The end must be after the start.");
        }

        if (priority is < 0 or > MaxPriority)
        {
            return Error.Validation("Campaign.PriorityInvalid", $"Priority is between 0 and {MaxPriority}.");
        }

        if (dailyImpressionCap is < 1)
        {
            return Error.Validation("Campaign.DailyCapInvalid", "A daily cap must be at least 1.");
        }

        var distinct = targets
            .Select(t => (Code: t.CategoryCode.Trim().ToLowerInvariant(), t.StateId))
            .Distinct()
            .ToList();
        if (distinct.Count is 0 or > MaxTargets || distinct.Any(t => t.Code.Length == 0))
        {
            return Error.Validation("Campaign.TargetsInvalid", $"Between 1 and {MaxTargets} category targets are required.");
        }

        Name = n;
        Placement = placement;
        Title = creative.Title;
        Body = creative.Body;
        CtaLabel = creative.CtaLabel;
        // AbsoluteUri keeps the advertiser's escapes (%26, %2F…); ToString() would decode them and change the link.
        CtaUrl = creative.CtaUrl.AbsoluteUri;
        ImageUrl = creative.ImageUrl?.AbsoluteUri;
        StartsAtUtc = startsAtUtc;
        EndsAtUtc = endsAtUtc;
        Priority = priority;
        DailyImpressionCap = dailyImpressionCap;

        // Replace the target set; removed rows are deleted as orphans of the aggregate.
        _targets.RemoveAll(existing => !distinct.Contains((existing.CategoryCode, existing.StateId)));
        foreach (var (code, stateId) in distinct)
        {
            if (!_targets.Any(t => t.CategoryCode == code && t.StateId == stateId))
            {
                _targets.Add(new CampaignTarget(Guid.CreateVersion7(), code, stateId));
            }
        }

        return Result.Success();
    }

    public Result Activate(DateTimeOffset nowUtc)
    {
        if (Status == CampaignStatus.Ended)
        {
            return Error.BusinessRule("Campaign.Ended", "An ended campaign cannot be activated.");
        }

        if (nowUtc >= EndsAtUtc)
        {
            return Error.BusinessRule("Campaign.ScheduleOver", "The campaign's schedule has already finished.");
        }

        Status = CampaignStatus.Active;
        return Result.Success();
    }

    public Result Pause()
    {
        if (Status != CampaignStatus.Active)
        {
            return Error.BusinessRule("Campaign.NotActive", "Only an active campaign can be paused.");
        }

        Status = CampaignStatus.Paused;
        return Result.Success();
    }

    public void End() => Status = CampaignStatus.Ended;

    public bool IsServableAt(DateTimeOffset nowUtc) =>
        Status == CampaignStatus.Active && nowUtc >= StartsAtUtc && nowUtc < EndsAtUtc;
}
