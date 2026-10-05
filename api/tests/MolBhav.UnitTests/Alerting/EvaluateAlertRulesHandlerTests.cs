using MolBhav.Application.Abstractions.Alerting;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Alerting.EvaluateAlertRules;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Pricing;
using MolBhav.Domain.Pricing.Events;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Alerting;

public sealed class EvaluateAlertRulesHandlerTests
{
    private static readonly DateOnly Today = new(2026, 10, 4);

    private readonly IAlertRuleRepository _rules = Substitute.For<IAlertRuleRepository>();
    private readonly IAlertRepository _alerts = Substitute.For<IAlertRepository>();
    private readonly IPriceRecordRepository _records = Substitute.For<IPriceRecordRepository>();
    private readonly IUnitOfWork _unitOfWork = Substitute.For<IUnitOfWork>();
    private readonly Guid _user = Guid.CreateVersion7();
    private readonly Guid _product = Guid.CreateVersion7();
    private readonly Guid _mandi = Guid.CreateVersion7();

    private EvaluateAlertRulesHandler CreateHandler() =>
        new(_rules, _alerts, _records, _unitOfWork, new FixedTimeProvider(new DateTimeOffset(2026, 10, 4, 6, 0, 0, TimeSpan.Zero)));

    private AlertRule Rule(AlertThresholdType type, decimal? percent = null, decimal? price = null) =>
        AlertRule.Create(_user, _product, null, LocationKind.Mandi, _mandi, null, type, percent, price).Value;

    private PriceRecord Previous(decimal modal) =>
        PriceRecord.Create(_product, null, Guid.CreateVersion7(), LocationKind.Mandi, _mandi, null, Guid.CreateVersion7(), null, null, modal, null, Today.AddDays(-1)).Value;

    private PriceRecordedDomainEvent Recorded(decimal modal) =>
        new(Guid.CreateVersion7(), _product, null, LocationKind.Mandi, _mandi, null, modal, Today);

    private void Given(AlertRule rule, decimal previousModal)
    {
        _rules.GetActiveByProductAsync(_product, Arg.Any<CancellationToken>()).Returns(new[] { rule });
        _records.GetPreviousAsync(_product, null, LocationKind.Mandi, _mandi, null, Today, Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(Previous(previousModal));
    }

    [Theory]
    [InlineData(2000, 2200, true)]  // +10% — the case the old "changes by %" (PriceDrop only) missed
    [InlineData(2000, 1800, true)]  // −10%
    [InlineData(2000, 2100, false)] // +5% — below the 10% threshold
    public async Task PriceChange_FiresOnAMoveEitherWay(decimal previous, decimal current, bool fires)
    {
        Given(Rule(AlertThresholdType.PriceChange, percent: 10m), previous);

        await CreateHandler().HandleAsync(Recorded(current), CancellationToken.None);

        _alerts.Received(fires ? 1 : 0).Add(Arg.Any<Alert>());
        await _unitOfWork.Received(fires ? 1 : 0).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task PriceDrop_IgnoresARise()
    {
        Given(Rule(AlertThresholdType.PriceDrop, percent: 10m), 2000m);

        await CreateHandler().HandleAsync(Recorded(2400m), CancellationToken.None);

        _alerts.DidNotReceive().Add(Arg.Any<Alert>());
    }

    [Fact]
    public async Task PriceBelow_FiresOnlyOnTheCrossing()
    {
        Given(Rule(AlertThresholdType.PriceBelow, price: 1900m), 2000m);

        await CreateHandler().HandleAsync(Recorded(1850m), CancellationToken.None);

        _alerts.Received(1).Add(Arg.Is<Alert>(a => a.NewPrice == 1850m && a.PreviousPrice == 2000m));
    }

    [Fact]
    public async Task UnchangedPrice_NeverAlerts()
    {
        Given(Rule(AlertThresholdType.PriceAbove, price: 1500m), 2000m);

        await CreateHandler().HandleAsync(Recorded(2000m), CancellationToken.None);

        _alerts.DidNotReceive().Add(Arg.Any<Alert>());
    }

    [Fact]
    public void PriceChange_IsAPercentRule()
    {
        Assert.True(AlertRule.IsPercentType(AlertThresholdType.PriceChange));
        Assert.True(AlertRule.Create(_user, _product, null, null, null, null, AlertThresholdType.PriceChange, null, 1500m).IsFailure);
    }
}
