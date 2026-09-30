using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Ingestion;

/// <summary>
/// One fetched-but-unusable row from a <see cref="DataIngestionJob"/> run (BRD §19: DataIngestionErrors) — e.g. an
/// unknown product code, an unmapped mandi/supplier code, or a value that failed <c>PriceRecord</c> validation.
/// The raw payload is kept verbatim so an admin can see exactly what the source sent. Its own aggregate (not owned
/// by the job) so it can be paged independently of the job's size. Never deleted — ingestion audit trail.
/// </summary>
public sealed class DataIngestionError : AggregateRoot<Guid>, IAuditableEntity
{
    public const int RawPayloadMaxLength = 4000;
    public const int ErrorMessageMaxLength = 500;

    private DataIngestionError(Guid id, Guid jobId, string rawPayload, string errorMessage, DateTimeOffset occurredAtUtc)
        : base(id)
    {
        JobId = jobId;
        RawPayload = rawPayload;
        ErrorMessage = errorMessage;
        OccurredAtUtc = occurredAtUtc;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private DataIngestionError()
    {
        RawPayload = string.Empty;
        ErrorMessage = string.Empty;
    }

    public Guid JobId { get; private set; }

    /// <summary>The source record verbatim (as JSON), truncated to <see cref="RawPayloadMaxLength"/> — for admin diagnosis, not re-processing.</summary>
    public string RawPayload { get; private set; }

    public string ErrorMessage { get; private set; }

    public DateTimeOffset OccurredAtUtc { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<DataIngestionError> Create(Guid jobId, string? rawPayload, string? errorMessage, DateTimeOffset occurredAtUtc)
    {
        if (jobId == Guid.Empty)
        {
            return Error.Validation("DataIngestionError.JobRequired", "Job is required.");
        }

        if (string.IsNullOrWhiteSpace(errorMessage))
        {
            return Error.Validation("DataIngestionError.MessageRequired", "Error message is required.");
        }

        var payload = Truncate(rawPayload ?? string.Empty, RawPayloadMaxLength);
        var message = Truncate(errorMessage, ErrorMessageMaxLength);

        return new DataIngestionError(Guid.CreateVersion7(), jobId, payload, message, occurredAtUtc);
    }

    private static string Truncate(string value, int maxLength) => value.Length <= maxLength ? value : value[..maxLength];
}
