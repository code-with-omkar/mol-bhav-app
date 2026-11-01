using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Ingestion.Admin.ImportIngestionFile;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Pricing;
using MolBhav.Infrastructure.Ingestion;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Ingestion;

public sealed class IngestionDropFolderBackgroundServiceTests : IDisposable
{
    // Files get their real write time, so the clock must be later than that for them to count as settled.
    private static readonly DateTimeOffset Now = DateTimeOffset.UtcNow.AddHours(1);

    private readonly string _root = Path.Combine(Path.GetTempPath(), "molbhav-drop-" + Guid.NewGuid().ToString("N"));
    private readonly ISender _sender = Substitute.For<ISender>();
    private readonly IPriceSourceRepository _sources = Substitute.For<IPriceSourceRepository>();
    private readonly PriceSource _source = PriceSource.Create("agmarknet", "Agmarknet", Guid.CreateVersion7()).Value;
    private readonly Guid _admin = Guid.CreateVersion7();

    public IngestionDropFolderBackgroundServiceTests()
    {
        Directory.CreateDirectory(Path.Combine(_root, "agmarknet"));
        _sources.GetActiveAsync(Arg.Any<CancellationToken>()).Returns([_source]);
    }

    public void Dispose() => Directory.Delete(_root, recursive: true);

    private IngestionDropFolderBackgroundService CreateService(long maxFileBytes = 1024)
    {
        var services = new ServiceCollection();
        services.AddSingleton(_sender);
        services.AddSingleton(_sources);
        var options = Options.Create(new IngestionDropFolderOptions
        {
            Enabled = true,
            StableSeconds = 0,
            UploadAsUserId = _admin,
            MaxFileBytes = maxFileBytes,
        });
        var environment = Substitute.For<IHostEnvironment>();
        return new IngestionDropFolderBackgroundService(
            services.BuildServiceProvider().GetRequiredService<IServiceScopeFactory>(),
            options,
            new FixedTimeProvider(Now),
            environment,
            NullLogger<IngestionDropFolderBackgroundService>.Instance);
    }

    private string Drop(string folder, string name, string content = "market,commodity\n")
    {
        var directory = Path.Combine(_root, folder);
        Directory.CreateDirectory(directory);
        var path = Path.Combine(directory, name);
        File.WriteAllText(path, content);
        return path;
    }

    private string[] Files(string folder) =>
        Directory.Exists(Path.Combine(_root, folder)) ? Directory.GetFiles(Path.Combine(_root, folder), "*", SearchOption.AllDirectories) : [];

    [Fact]
    public async Task Successful_import_sends_the_command_as_the_configured_admin_and_moves_the_file_to_processed()
    {
        var path = Drop("agmarknet", "report.csv");
        var jobId = Guid.CreateVersion7();
        _sender.Send(Arg.Any<ImportIngestionFileCommand>(), Arg.Any<CancellationToken>())
            .Returns(Result.Success(new CreatedResponse(jobId)));

        var imported = await CreateService().ScanOnceAsync(_root, CancellationToken.None);

        Assert.Equal(1, imported);
        Assert.False(File.Exists(path));
        Assert.Single(Files("processed"));
        Assert.Empty(Files("failed"));
        await _sender.Received(1).Send(
            Arg.Is<ImportIngestionFileCommand>(c => c.PriceSourceId == _source.Id && c.UploadedByUserId == _admin && c.FileName == "report.csv"),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Rejected_import_moves_the_file_to_failed_with_the_reason()
    {
        Drop("agmarknet", "bad.csv");
        _sender.Send(Arg.Any<ImportIngestionFileCommand>(), Arg.Any<CancellationToken>())
            .Returns(Result.Failure<CreatedResponse>(Error.Validation("Ingestion.FileUnreadable", "No header row found.")));

        var imported = await CreateService().ScanOnceAsync(_root, CancellationToken.None);

        Assert.Equal(0, imported);
        var failed = Files("failed");
        Assert.Equal(2, failed.Length);
        Assert.Contains("No header row found.", File.ReadAllText(failed.Single(f => f.EndsWith(".error.txt", StringComparison.Ordinal))));
    }

    [Fact]
    public async Task Unknown_source_folder_is_rejected_without_sending_anything()
    {
        Drop("nope", "report.csv");

        await CreateService().ScanOnceAsync(_root, CancellationToken.None);

        Assert.Equal(2, Files("failed").Length);
        await _sender.DidNotReceiveWithAnyArgs().Send(default(ImportIngestionFileCommand)!, default);
    }

    [Fact]
    public async Task Oversized_file_is_rejected_unread()
    {
        Drop("agmarknet", "big.csv", new string('x', 2048));

        await CreateService(maxFileBytes: 1024).ScanOnceAsync(_root, CancellationToken.None);

        Assert.Equal(2, Files("failed").Length);
        await _sender.DidNotReceiveWithAnyArgs().Send(default(ImportIngestionFileCommand)!, default);
    }

    [Fact]
    public async Task Transient_failure_leaves_the_file_for_the_next_pass()
    {
        var path = Drop("agmarknet", "report.csv");
        _sender.Send(Arg.Any<ImportIngestionFileCommand>(), Arg.Any<CancellationToken>())
            .Returns<Result<CreatedResponse>>(_ => throw new InvalidOperationException("db down"));

        var imported = await CreateService().ScanOnceAsync(_root, CancellationToken.None);

        Assert.Equal(0, imported);
        Assert.True(File.Exists(path));
        Assert.Empty(Files("failed"));
        Assert.Empty(Files("processed"));
    }

    [Fact]
    public async Task Non_csv_files_and_the_processed_and_failed_folders_are_ignored()
    {
        Drop("agmarknet", "notes.txt");
        Drop("processed/agmarknet", "old.csv");
        Drop("failed/agmarknet", "older.csv");

        var imported = await CreateService().ScanOnceAsync(_root, CancellationToken.None);

        Assert.Equal(0, imported);
        await _sender.DidNotReceiveWithAnyArgs().Send(default(ImportIngestionFileCommand)!, default);
    }
}
