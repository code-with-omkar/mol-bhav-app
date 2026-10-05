using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Admin.BackfillIngestion;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class IngestionRunAndBackfillTests
{
    // 4 Oct 2026 21:00 UTC = 5 Oct 2026 02:30 IST.
    private static readonly DateTimeOffset LateNightUtc = new(2026, 10, 4, 21, 0, 0, TimeSpan.Zero);
    private static readonly DateOnly IstToday = new(2026, 10, 5);

    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly IIngestionBackfillQueue _queue = Substitute.For<IIngestionBackfillQueue>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;
    private readonly Guid _admin = Guid.CreateVersion7();

    public IngestionRunAndBackfillTests()
    {
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
        _queue.TryEnqueue(Arg.Any<IngestionBackfillRequest>()).Returns(true);
    }

    private BackfillIngestionCommandHandler CreateHandler() => new(_sources, _queue, new FixedTimeProvider(LateNightUtc));

    [Fact]
    public void IngestionDates_UseTheIstCalendarDay()
    {
        Assert.Equal(IstToday, IngestionDates.TodayIst(LateNightUtc));
        Assert.Equal(IstToday.AddDays(-1), IngestionDates.DefaultAsOf(LateNightUtc));
        Assert.Equal(IstToday, IngestionDates.DefaultAsOf(LateNightUtc, 0));
    }

    [Fact]
    public void Start_FutureAsOfDate_Fails()
    {
        var result = DataIngestionJob.Start(_source.Id, IngestionTriggerType.Scheduled, null, IstToday.AddDays(1), LateNightUtc);

        Assert.Equal("DataIngestionJob.FutureDate", result.Error.Code);
    }

    [Fact]
    public void Complete_OnlyUnchangedRows_IsASuccess()
    {
        var job = DataIngestionJob.Start(_source.Id, IngestionTriggerType.Scheduled, null, IstToday, LateNightUtc).Value;

        job.Complete(recordsFetched: 40, recordsPersisted: 0, recordsUnchanged: 40, recordsFailed: 0, LateNightUtc);

        Assert.Equal(IngestionJobStatus.Succeeded, job.Status);
        Assert.Equal(IstToday, job.AsOfDate);
        Assert.Equal(40, job.RecordsUnchanged);
    }

    [Fact]
    public void Complete_UnchangedAndFailedRows_IsPartial()
    {
        var job = DataIngestionJob.Start(_source.Id, IngestionTriggerType.Scheduled, null, IstToday, LateNightUtc).Value;

        job.Complete(recordsFetched: 10, recordsPersisted: 0, recordsUnchanged: 7, recordsFailed: 3, LateNightUtc);

        Assert.Equal(IngestionJobStatus.PartiallySucceeded, job.Status);
    }

    [Fact]
    public void PriceRecord_HasSameFigures_ComparesEveryFigure()
    {
        var record = PriceRecord.Create(
            Guid.CreateVersion7(), null, Guid.CreateVersion7(), LocationKind.Mandi, Guid.CreateVersion7(), null,
            _source.Id, 1000m, 1400m, 1200m, 55m, IstToday.AddDays(-1)).Value;

        Assert.True(record.HasSameFigures(1000m, 1400m, 1200m, 55m));
        Assert.False(record.HasSameFigures(1000m, 1400m, 1250m, 55m));
        Assert.False(record.HasSameFigures(null, 1400m, 1200m, 55m));
    }

    [Fact]
    public async Task Backfill_QueuesOneDatePerDayOldestFirst()
    {
        var command = new BackfillIngestionCommand(_source.Id, IstToday.AddDays(-2), IstToday, _admin);

        var result = await CreateHandler().Handle(command, CancellationToken.None);

        Assert.Equal(3, result.Value.Days);
        _queue.Received(1).TryEnqueue(Arg.Is<IngestionBackfillRequest>(r =>
            r.PriceSourceIds.SequenceEqual(new[] { _source.Id })
            && r.RequestedByUserId == _admin
            && r.Dates.SequenceEqual(new[] { IstToday.AddDays(-2), IstToday.AddDays(-1), IstToday })));
    }

    [Fact]
    public async Task Backfill_FutureEndDate_IsRejected()
    {
        var command = new BackfillIngestionCommand(_source.Id, IstToday, IstToday.AddDays(1), _admin);

        var result = await CreateHandler().Handle(command, CancellationToken.None);

        Assert.Equal("Ingestion.BackfillFuture", result.Error.Code);
        _queue.DidNotReceive().TryEnqueue(Arg.Any<IngestionBackfillRequest>());
    }

    [Fact]
    public async Task Backfill_QueueFull_ReturnsBusy()
    {
        _queue.TryEnqueue(Arg.Any<IngestionBackfillRequest>()).Returns(false);

        var result = await CreateHandler().Handle(
            new BackfillIngestionCommand(_source.Id, IstToday.AddDays(-1), IstToday.AddDays(-1), _admin), CancellationToken.None);

        Assert.Equal("Ingestion.BackfillBusy", result.Error.Code);
    }

    [Fact]
    public void BackfillValidator_RejectsReversedAndOverlongRanges()
    {
        var validator = new BackfillIngestionCommandValidator();

        Assert.False(validator.Validate(new BackfillIngestionCommand(_source.Id, IstToday, IstToday.AddDays(-1), _admin)).IsValid);
        Assert.False(validator.Validate(new BackfillIngestionCommand(
            _source.Id, IstToday.AddDays(-IngestionDates.MaxBackfillDays), IstToday, _admin)).IsValid);
        Assert.True(validator.Validate(new BackfillIngestionCommand(
            _source.Id, IstToday.AddDays(-(IngestionDates.MaxBackfillDays - 1)), IstToday, _admin)).IsValid);
    }
}
