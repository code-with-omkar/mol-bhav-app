using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Promotions;

namespace MolBhav.UnitTests.Promotions;

public sealed class CampaignTests
{
    private static readonly DateTimeOffset Start = new(2026, 10, 1, 0, 0, 0, TimeSpan.Zero);
    private static readonly DateTimeOffset End = Start.AddDays(30);
    private static readonly string[] ExpectedCodesAfterUpdate = ["agriculture", "dairy"];

    private static CampaignCreative Creative() =>
        CampaignCreative.Create("Onion seed", "Certified seed near you.", "Get a quote", "https://example.com/q", null).Value;

    private static Result<Campaign> Create(
        IReadOnlyCollection<(string, Guid?)>? targets = null,
        DateTimeOffset? starts = null,
        DateTimeOffset? ends = null,
        int priority = 10,
        int? cap = null,
        string name = "Kisan – Oct") =>
        Campaign.Create(
            Guid.NewGuid(), name, PromotionPlacement.HomeFeed, Creative(), starts ?? Start, ends ?? End, priority, cap,
            targets ?? [("agriculture", null)]);

    [Fact]
    public void Create_Valid_IsDraftWithTargets()
    {
        var campaign = Create().Value;

        Assert.Equal(CampaignStatus.Draft, campaign.Status);
        Assert.Single(campaign.Targets);
        Assert.False(campaign.IsServableAt(Start.AddDays(1)));
    }

    [Fact]
    public void Create_EmptyAdvertiser_Fails()
    {
        var result = Campaign.Create(
            Guid.Empty, "x", PromotionPlacement.HomeFeed, Creative(), Start, End, 0, null, [("agriculture", null)]);

        Assert.Equal("Campaign.AdvertiserRequired", result.Error.Code);
    }

    [Fact]
    public void Create_EndNotAfterStart_Fails() =>
        Assert.Equal("Campaign.ScheduleInvalid", Create(starts: Start, ends: Start).Error.Code);

    [Theory]
    [InlineData(-1)]
    [InlineData(Campaign.MaxPriority + 1)]
    public void Create_PriorityOutOfRange_Fails(int priority) =>
        Assert.Equal("Campaign.PriorityInvalid", Create(priority: priority).Error.Code);

    [Fact]
    public void Create_ZeroDailyCap_Fails() =>
        Assert.Equal("Campaign.DailyCapInvalid", Create(cap: 0).Error.Code);

    [Fact]
    public void Create_NoTargets_Fails() =>
        Assert.Equal("Campaign.TargetsInvalid", Create(targets: []).Error.Code);

    [Fact]
    public void Create_DuplicateTargetsInDifferentCase_AreMerged()
    {
        var campaign = Create(targets: [("Agriculture", null), ("agriculture ", null)]).Value;

        Assert.Equal("agriculture", Assert.Single(campaign.Targets).CategoryCode);
    }

    [Fact]
    public void Update_ReplacesTargets_KeepingUnchangedRows()
    {
        var state = Guid.NewGuid();
        var campaign = Create(targets: [("agriculture", null), ("construction", state)]).Value;
        var kept = campaign.Targets.Single(t => t.CategoryCode == "agriculture");

        var result = campaign.Update(
            "Kisan – Oct", PromotionPlacement.MandiPrices, Creative(), Start, End, 10, null, [("agriculture", null), ("dairy", null)]);

        Assert.True(result.IsSuccess);
        Assert.Equal(PromotionPlacement.MandiPrices, campaign.Placement);
        Assert.Equal(ExpectedCodesAfterUpdate, campaign.Targets.Select(t => t.CategoryCode).Order());
        Assert.Contains(kept, campaign.Targets);
    }

    [Fact]
    public void Activate_InsideSchedule_IsServable()
    {
        var campaign = Create().Value;

        Assert.True(campaign.Activate(Start.AddDays(-1)).IsSuccess);

        Assert.False(campaign.IsServableAt(Start.AddTicks(-1)));
        Assert.True(campaign.IsServableAt(Start));
        Assert.False(campaign.IsServableAt(End));
    }

    [Fact]
    public void Activate_AfterScheduleEnded_Fails()
    {
        var campaign = Create().Value;

        Assert.Equal("Campaign.ScheduleOver", campaign.Activate(End).Error.Code);
        Assert.Equal(CampaignStatus.Draft, campaign.Status);
    }

    [Fact]
    public void Pause_NotActive_Fails() =>
        Assert.Equal("Campaign.NotActive", Create().Value.Pause().Error.Code);

    [Fact]
    public void Pause_Active_StopsServing()
    {
        var campaign = Create().Value;
        campaign.Activate(Start);

        Assert.True(campaign.Pause().IsSuccess);
        Assert.False(campaign.IsServableAt(Start.AddDays(1)));
    }

    [Fact]
    public void End_IsTerminal()
    {
        var campaign = Create().Value;
        campaign.End();

        Assert.Equal("Campaign.Ended", campaign.Activate(Start).Error.Code);
        Assert.Equal(
            "Campaign.Ended",
            campaign.Update("x", PromotionPlacement.HomeFeed, Creative(), Start, End, 0, null, [("agriculture", null)]).Error.Code);
    }

    [Fact]
    public void Create_StoresLinkWithEscapesIntact()
    {
        const string url = "https://example.com/?q=a%26b&p=x%2Fy";
        var creative = CampaignCreative.Create("t", "b", "c", url, null).Value;

        var campaign = Campaign.Create(
            Guid.NewGuid(), "x", PromotionPlacement.HomeFeed, creative, Start, End, 0, null, [("agriculture", null)]).Value;

        Assert.Equal(url, campaign.CtaUrl);
    }
}
