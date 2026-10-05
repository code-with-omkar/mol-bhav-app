using System.Text.Json;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Application.Features.Ingestion.Common;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;

namespace MolBhav.Application.Features.Ingestion.Admin.ImportIngestionFile;

/// <summary>
/// Parses the file, then stores its rows through the same <see cref="IngestionRecordWriter"/> as an API run — so an
/// upload and a later API pull for the same day never duplicate each other (identical rows show as unchanged).
/// Lines the parser rejects become job errors next to the rows the writer rejects. One transaction for the whole file.
/// </summary>
internal sealed class ImportIngestionFileCommandHandler(
    IDataIngestionJobRepository jobs,
    IPriceSourceRepository sources,
    IIngestionFileParser parser,
    IngestionRecordWriter writer,
    TimeProvider timeProvider) : ICommandHandler<ImportIngestionFileCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(ImportIngestionFileCommand request, CancellationToken cancellationToken)
    {
        var source = await sources.GetByIdAsync(request.PriceSourceId, cancellationToken);
        if (source is null)
        {
            return Error.NotFound("PriceSource.NotFound", "Price source not found.");
        }

        if (!source.IsActive)
        {
            return Error.Validation("PriceSource.Inactive", "Cannot import prices for an inactive price source.");
        }

        var parsed = await parser.ParseAsync(source.Code, request.Content, cancellationToken);
        if (!parsed.IsSuccess)
        {
            // Nothing usable in the file: tell the admin now instead of recording an empty job.
            return Error.Validation("Ingestion.FileUnreadable", parsed.FailureReason ?? "The file could not be read.");
        }

        var now = timeProvider.GetUtcNow();
        var today = IngestionDates.TodayIst(now);

        // The job's market day is the latest date in the file (a file can hold several days).
        var asOfDate = parsed.Records.Count == 0 ? today : parsed.Records.Max(r => r.RecordDate);
        if (asOfDate > today)
        {
            return Error.Validation("Ingestion.FileFutureDate", $"The file has prices dated {asOfDate:yyyy-MM-dd}, which is in the future.");
        }

        var jobResult = DataIngestionJob.Start(source.Id, IngestionTriggerType.Upload, request.UploadedByUserId, asOfDate, now);
        if (jobResult.IsFailure)
        {
            return Result.Failure<CreatedResponse>(jobResult.Error);
        }

        var job = jobResult.Value;
        jobs.Add(job);

        foreach (var line in parsed.LineErrors)
        {
            writer.RecordError(
                job,
                JsonSerializer.Serialize(new { file = request.FileName, line = line.LineNumber, text = line.RawLine }),
                $"Line {line.LineNumber}: {line.Message}");
        }

        var counts = await writer.WriteAsync(job, source.CategoryId, parsed.Records, cancellationToken);
        job.Complete(
            counts.Fetched + parsed.LineErrors.Count,
            counts.Persisted,
            counts.Unchanged,
            counts.Failed + parsed.LineErrors.Count,
            timeProvider.GetUtcNow());

        return new CreatedResponse(job.Id);
    }
}
