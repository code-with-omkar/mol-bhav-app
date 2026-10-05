using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Admin.UpdateIngestionSchedule;
using MolBhav.Application.Features.Ingestion.Scheduling.ClaimDueIngestionSchedule;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class UpdateIngestionScheduleCommandHandlerTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 4, 3, 30, 0, TimeSpan.Zero); // 09:00 IST

    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly IIngestionScheduleRepository _schedules = Substitute.For<IIngestionScheduleRepository>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;

    public UpdateIngestionScheduleCommandHandlerTests()
    {
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
    }

    private UpdateIngestionScheduleCommandHandler CreateHandler() => new(_sources, _schedules, new FixedTimeProvider(Now));

    private UpdateIngestionScheduleCommand Daily(string time = "18:00", bool enabled = true) =>
        new(_source.Id, enabled, IngestionScheduleFrequency.Daily, time, null, null);

    [Fact]
    public async Task Handle_FirstSchedule_AddsIt()
    {
        _schedules.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns((IngestionSchedule?)null);

        var result = await CreateHandler().Handle(Daily(), CancellationToken.None);

        Assert.True(result.IsSuccess);
        _schedules.Received(1).Add(Arg.Is<IngestionSchedule>(s =>
            s.PriceSourceId == _source.Id && s.IsEnabled && s.TimeOfDay == new TimeOnly(18, 0)));
    }

    [Fact]
    public async Task Handle_ExistingSchedule_ReconfiguresInPlace()
    {
        var existing = IngestionSchedule.Create(_source.Id, true, IngestionScheduleFrequency.Daily, new TimeOnly(6, 0), null, null, Now).Value;
        _schedules.GetByPriceSourceIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(existing);

        var result = await CreateHandler().Handle(Daily(enabled: false), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.False(existing.IsEnabled);
        Assert.Null(existing.NextRunAtUtc);
        _schedules.DidNotReceive().Add(Arg.Any<IngestionSchedule>());
    }

    [Fact]
    public async Task Handle_UnknownSource_ReturnsNotFound()
    {
        var command = Daily() with { PriceSourceId = Guid.CreateVersion7() };

        var result = await CreateHandler().Handle(command, CancellationToken.None);

        Assert.Equal("PriceSource.NotFound", result.Error.Code);
        _schedules.DidNotReceive().Add(Arg.Any<IngestionSchedule>());
    }

    [Fact]
    public void Validator_RejectsBadTimeAndMissingWeeklyDay()
    {
        var validator = new UpdateIngestionScheduleCommandValidator();

        Assert.False(validator.Validate(Daily(time: "25:00")).IsValid);
        Assert.False(validator.Validate(Daily(time: "6pm")).IsValid);
        Assert.False(validator.Validate(new UpdateIngestionScheduleCommand(
            _source.Id, true, IngestionScheduleFrequency.Weekly, "06:00", null, null)).IsValid);
        Assert.True(validator.Validate(Daily()).IsValid);
    }

    [Fact]
    public async Task Claim_DueSchedule_AdvancesItAndReturnsTheSource()
    {
        var schedule = IngestionSchedule.Create(_source.Id, true, IngestionScheduleFrequency.Daily, new TimeOnly(6, 0), null, null, Now.AddDays(-1)).Value;
        _schedules.GetByIdAsync(schedule.Id, Arg.Any<CancellationToken>()).Returns(schedule);
        var handler = new ClaimDueIngestionScheduleCommandHandler(_schedules, new FixedTimeProvider(Now));

        var result = await handler.Handle(new ClaimDueIngestionScheduleCommand(schedule.Id), CancellationToken.None);

        Assert.Equal(_source.Id, result.Value);
        Assert.Equal(Now, schedule.LastRunAtUtc);
        Assert.True(schedule.NextRunAtUtc > Now);
    }

    [Fact]
    public async Task Claim_NotDueSchedule_ReturnsNull()
    {
        var schedule = IngestionSchedule.Create(_source.Id, true, IngestionScheduleFrequency.Daily, new TimeOnly(18, 0), null, null, Now).Value;
        _schedules.GetByIdAsync(schedule.Id, Arg.Any<CancellationToken>()).Returns(schedule);
        var handler = new ClaimDueIngestionScheduleCommandHandler(_schedules, new FixedTimeProvider(Now));

        var result = await handler.Handle(new ClaimDueIngestionScheduleCommand(schedule.Id), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Null(result.Value);
        Assert.Null(schedule.LastRunAtUtc);
    }
}
