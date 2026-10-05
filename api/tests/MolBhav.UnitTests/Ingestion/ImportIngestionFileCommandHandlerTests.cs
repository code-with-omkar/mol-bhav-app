using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Admin.ImportIngestionFile;
using MolBhav.Application.Features.Ingestion.Common;
using MolBhav.Domain.Catalog;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.Pricing;
using MolBhav.Domain.SharedKernel;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class ImportIngestionFileCommandHandlerTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 4, 6, 0, 0, TimeSpan.Zero); // 11:30 IST

    private readonly IDataIngestionJobRepository _jobs = Substitute.For<IDataIngestionJobRepository>();
    private readonly IDataIngestionErrorRepository _errors = Substitute.For<IDataIngestionErrorRepository>();
    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly IIngestionFileParser _parser = Substitute.For<IIngestionFileParser>();
    private readonly IProductRepository _products = Substitute.For<IProductRepository>();
    private readonly IProcurementCategoryRepository _categories = Substitute.For<IProcurementCategoryRepository>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;
    private readonly Guid _admin = Guid.CreateVersion7();

    public ImportIngestionFileCommandHandlerTests()
    {
        _sources.GetByIdAsync(_source.Id, Arg.Any<CancellationToken>()).Returns(_source);
    }

    private ImportIngestionFileCommandHandler CreateHandler()
    {
        var time = new FixedTimeProvider(Now);
        var writer = new IngestionRecordWriter(
            _errors,
            Substitute.For<IPriceRecordRepository>(),
            _products,
            _categories,
            Substitute.For<IMandiRepository>(),
            Substitute.For<ISupplierRepository>(),
            time);
        return new ImportIngestionFileCommandHandler(_jobs, _sources, _parser, writer, time);
    }

    private ImportIngestionFileCommand Command() =>
        new(_source.Id, _admin, "prices.csv", 100, new MemoryStream([1]));

    [Fact]
    public async Task UnreadableFile_IsRejectedWithoutCreatingAJob()
    {
        _parser.ParseAsync(Arg.Any<string>(), Arg.Any<Stream>(), Arg.Any<CancellationToken>())
            .Returns(IngestionFileParseResult.Failed("No header row found."));

        var result = await CreateHandler().Handle(Command(), CancellationToken.None);

        Assert.Equal("Ingestion.FileUnreadable", result.Error.Code);
        _jobs.DidNotReceive().Add(Arg.Any<DataIngestionJob>());
    }

    [Fact]
    public async Task LineErrors_AreRecordedAndCountedAsFailed()
    {
        // No records the writer can resolve here (repositories return nothing), only parser line errors:
        // the job must still be created as an Upload job, dated today, with those lines as errors.
        _parser.ParseAsync(Arg.Any<string>(), Arg.Any<Stream>(), Arg.Any<CancellationToken>())
            .Returns(IngestionFileParseResult.Success(
                [],
                [new IngestionFileLineError(3, "Lasalgaon,,FAQ", "Commodity is missing.")]));
        DataIngestionJob? job = null;
        _jobs.When(j => j.Add(Arg.Any<DataIngestionJob>())).Do(call => job = call.Arg<DataIngestionJob>());

        var result = await CreateHandler().Handle(Command(), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.NotNull(job);
        Assert.Equal(IngestionTriggerType.Upload, job.TriggerType);
        Assert.Equal(_admin, job.TriggeredByUserId);
        Assert.Equal(new DateOnly(2026, 10, 4), job.AsOfDate);
        Assert.Equal(1, job.RecordsFailed);
        Assert.Equal(IngestionJobStatus.Failed, job.Status);
        _errors.Received(1).Add(Arg.Is<DataIngestionError>(e => e.ErrorMessage.StartsWith("Line 3:", StringComparison.Ordinal)));
    }

    [Fact]
    public async Task FutureDatedFile_IsRejected()
    {
        _parser.ParseAsync(Arg.Any<string>(), Arg.Any<Stream>(), Arg.Any<CancellationToken>())
            .Returns(IngestionFileParseResult.Success(
                [new IngestedPriceRecord("onion", null, LocationKind.Mandi, "lasalgaon", null, null, 1500m, null, new DateOnly(2026, 10, 9))],
                []));

        var result = await CreateHandler().Handle(Command(), CancellationToken.None);

        Assert.Equal("Ingestion.FileFutureDate", result.Error.Code);
    }

    [Fact]
    public void Validator_RejectsNonCsvAndOversizedFiles()
    {
        var validator = new ImportIngestionFileCommandValidator();

        Assert.False(validator.Validate(Command() with { FileName = "prices.xlsx" }).IsValid);
        Assert.False(validator.Validate(Command() with { FileLength = ImportIngestionFileCommandValidator.MaxFileBytes + 1 }).IsValid);
        Assert.False(validator.Validate(Command() with { FileLength = 0 }).IsValid);
        Assert.True(validator.Validate(Command()).IsValid);
    }

    [Fact]
    public async Task ProductFromAnotherCategory_IsRejectedAsRowError()
    {
        // Source is (say) agriculture; the file prices a product whose sub-category belongs to construction.
        var cementSubCategory = Guid.CreateVersion7();
        var cement = Product.Create(
            CatalogCode.Create("cement-opc-53").Value,
            cementSubCategory,
            Guid.CreateVersion7(),
            1,
            null,
            [CatalogTranslation.Create(LanguageCode.English, "OPC 53 cement").Value]).Value;
        _products.GetByCodeAsync(Arg.Any<CatalogCode>(), Arg.Any<CancellationToken>()).Returns(cement);
        _categories.GetSubCategoryIdsAsync(_source.CategoryId, Arg.Any<CancellationToken>())
            .Returns((IReadOnlySet<Guid>)new HashSet<Guid> { Guid.CreateVersion7() });
        _parser.ParseAsync(Arg.Any<string>(), Arg.Any<Stream>(), Arg.Any<CancellationToken>())
            .Returns(IngestionFileParseResult.Success(
                [new IngestedPriceRecord("cement-opc-53", null, LocationKind.Supplier, "pune-cement-depot", null, null, 410m, null, new DateOnly(2026, 10, 3))],
                []));
        DataIngestionJob? job = null;
        _jobs.When(j => j.Add(Arg.Any<DataIngestionJob>())).Do(call => job = call.Arg<DataIngestionJob>());

        var result = await CreateHandler().Handle(Command(), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.NotNull(job);
        Assert.Equal(1, job.RecordsFailed);
        Assert.Equal(0, job.RecordsPersisted);
        _errors.Received(1).Add(Arg.Is<DataIngestionError>(e => e.ErrorMessage.Contains("not in this source's category", StringComparison.Ordinal)));
    }
}
