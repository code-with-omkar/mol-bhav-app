using MolBhav.Application.Abstractions.FeatureSwitches;
using MolBhav.Application.Features.FeatureSwitches.GetFeatureSwitches;
using MolBhav.Application.Features.FeatureSwitches.SetFeatureSwitch;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.UnitTests.Admin;

public sealed class FeatureSwitchTests
{
    private readonly IFeatureSwitchRepository _switches = Substitute.For<IFeatureSwitchRepository>();

    [Fact]
    public void A_switch_can_be_turned_off_and_on()
    {
        var feature = FeatureSwitch.Create(AppFeature.Reports, false).Value;
        Assert.False(feature.IsEnabled);

        feature.SetEnabled(true);

        Assert.True(feature.IsEnabled);
        Assert.Equal(AppFeature.Reports, feature.Feature);
    }

    [Fact]
    public void An_unknown_feature_is_refused()
    {
        Assert.Equal("FeatureSwitch.FeatureInvalid", FeatureSwitch.Create((AppFeature)99, true).Error.Code);
    }

    [Fact]
    public async Task The_first_change_creates_the_switch_and_later_ones_edit_it()
    {
        _switches.GetByFeatureAsync(AppFeature.Ads, Arg.Any<CancellationToken>()).Returns((FeatureSwitch?)null);
        var handler = new SetFeatureSwitchCommandHandler(_switches);

        Assert.True((await handler.Handle(new(AppFeature.Ads, false), CancellationToken.None)).IsSuccess);
        _switches.Received(1).Add(Arg.Is<FeatureSwitch>(s => s.Feature == AppFeature.Ads && !s.IsEnabled));

        var existing = FeatureSwitch.Create(AppFeature.Ads, false).Value;
        _switches.GetByFeatureAsync(AppFeature.Ads, Arg.Any<CancellationToken>()).Returns(existing);

        Assert.True((await handler.Handle(new(AppFeature.Ads, true), CancellationToken.None)).IsSuccess);
        Assert.True(existing.IsEnabled);
        _switches.Received(1).Add(Arg.Any<FeatureSwitch>());
    }

    [Fact]
    public async Task Every_feature_is_listed_and_one_nobody_changed_is_on()
    {
        _switches.ListAsync(Arg.Any<CancellationToken>())
            .Returns([FeatureSwitch.Create(AppFeature.Reports, false).Value]);

        var list = (await new GetFeatureSwitchesQueryHandler(_switches).Handle(new GetFeatureSwitchesQuery(), CancellationToken.None)).Value;

        Assert.Equal(Enum.GetValues<AppFeature>(), list.Select(f => f.Feature));
        Assert.False(list.Single(f => f.Feature == AppFeature.Reports).IsEnabled);
        Assert.True(list.Single(f => f.Feature == AppFeature.Ads).IsEnabled);
        Assert.True(list.Single(f => f.Feature == AppFeature.CostEstimator).IsEnabled);
    }
}
