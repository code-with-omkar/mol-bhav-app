using System.Globalization;
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Admin.ImportIngestionFile;

namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Imports CSVs dropped in <c>&lt;root&gt;/&lt;source code&gt;/</c> through <see cref="ImportIngestionFileCommand"/> — the same path as the
/// admin upload, so the parser, validation, de-duplication and job/error records are identical. Each file is moved to
/// <c>processed</c> or (with a <c>.error.txt</c> beside it) <c>failed</c>, so nothing is imported twice and nothing fails silently.
/// </summary>
internal sealed partial class IngestionDropFolderBackgroundService(
    IServiceScopeFactory scopeFactory,
    IOptions<IngestionDropFolderOptions> options,
    TimeProvider timeProvider,
    IHostEnvironment environment,
    ILogger<IngestionDropFolderBackgroundService> logger) : BackgroundService
{
    internal const string ProcessedFolder = "processed";
    internal const string FailedFolder = "failed";

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var settings = options.Value;
        if (!settings.Enabled)
        {
            return;
        }

        var root = System.IO.Path.GetFullPath(settings.Path, environment.ContentRootPath);
        Directory.CreateDirectory(root);
        LogWatching(logger, root);

        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(settings.PollIntervalSeconds), timeProvider);

        try
        {
            do
            {
                try
                {
                    await ScanOnceAsync(root, stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    LogScanFailed(logger, ex);
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Graceful shutdown.
        }
    }

    /// <summary>One pass over <paramref name="root"/>; returns how many files were imported successfully.</summary>
    internal async Task<int> ScanOnceAsync(string root, CancellationToken cancellationToken)
    {
        var settings = options.Value;
        var imported = 0;

        Dictionary<string, Guid> sources;
        await using (var scope = scopeFactory.CreateAsyncScope())
        {
            var repository = scope.ServiceProvider.GetRequiredService<IPriceSourceRepository>();
            sources = (await repository.GetActiveAsync(cancellationToken))
                .ToDictionary(s => s.Code, s => s.Id, StringComparer.OrdinalIgnoreCase);
        }

        foreach (var directory in Directory.EnumerateDirectories(root))
        {
            var code = System.IO.Path.GetFileName(directory);
            if (code.Equals(ProcessedFolder, StringComparison.OrdinalIgnoreCase) || code.Equals(FailedFolder, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            foreach (var path in Directory.EnumerateFiles(directory, "*.csv").Order(StringComparer.OrdinalIgnoreCase))
            {
                cancellationToken.ThrowIfCancellationRequested();

                var file = new FileInfo(path);
                if (timeProvider.GetUtcNow() - file.LastWriteTimeUtc < TimeSpan.FromSeconds(settings.StableSeconds))
                {
                    continue; // still being copied; picked up on a later pass
                }

                if (!sources.TryGetValue(code, out var sourceId))
                {
                    Reject(root, file, code, $"No active price source with code '{code}'.");
                }
                else if (file.Length > settings.MaxFileBytes)
                {
                    Reject(root, file, code, $"File is {file.Length:N0} bytes; the limit is {settings.MaxFileBytes:N0}.");
                }
                else if (await ImportAsync(root, file, code, sourceId, settings.UploadAsUserId, cancellationToken))
                {
                    imported++;
                }
            }
        }

        return imported;
    }

    private async Task<bool> ImportAsync(string root, FileInfo file, string code, Guid sourceId, Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var sender = scope.ServiceProvider.GetRequiredService<ISender>();

            await using var content = file.OpenRead();
            var result = await sender.Send(new ImportIngestionFileCommand(sourceId, userId, file.Name, file.Length, content), cancellationToken);

            if (result.IsFailure)
            {
                content.Close();
                Reject(root, file, code, $"{result.Error.Code}: {result.Error.Description}");
                return false;
            }

            content.Close();
            var name = file.Name; // FileInfo.Name changes once the file is moved
            MoveTo(root, ProcessedFolder, file, code);
            LogImported(logger, name, code, result.Value.Id);
            return true;
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // Left in place: a transient failure (e.g. database down) is retried on the next pass.
            LogImportFailed(logger, file.Name, code, ex);
            return false;
        }
    }

    private void Reject(string root, FileInfo file, string code, string reason)
    {
        var name = file.Name;
        var target = MoveTo(root, FailedFolder, file, code);
        File.WriteAllText(target + ".error.txt", reason);
        LogRejected(logger, name, code, reason);
    }

    private string MoveTo(string root, string folder, FileInfo file, string code)
    {
        var directory = System.IO.Path.Combine(root, folder, code);
        Directory.CreateDirectory(directory);

        var stamp = timeProvider.GetUtcNow().ToString("yyyyMMddHHmmssfff", CultureInfo.InvariantCulture);
        var target = System.IO.Path.Combine(directory, $"{stamp}-{file.Name}");
        file.MoveTo(target);
        return target;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Ingestion drop folder watching {Root}")]
    private static partial void LogWatching(ILogger logger, string root);

    [LoggerMessage(Level = LogLevel.Information, Message = "Imported {File} for source {Source} (job {JobId})")]
    private static partial void LogImported(ILogger logger, string file, string source, Guid jobId);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Rejected {File} for source {Source}: {Reason}")]
    private static partial void LogRejected(ILogger logger, string file, string source, string reason);

    [LoggerMessage(Level = LogLevel.Error, Message = "Import of {File} for source {Source} failed; it will be retried")]
    private static partial void LogImportFailed(ILogger logger, string file, string source, Exception exception);

    [LoggerMessage(Level = LogLevel.Error, Message = "Ingestion drop folder scan failed")]
    private static partial void LogScanFailed(ILogger logger, Exception exception);
}
