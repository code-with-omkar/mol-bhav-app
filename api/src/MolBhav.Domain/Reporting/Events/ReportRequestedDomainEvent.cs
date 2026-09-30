using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Reporting.Events;

/// <summary>Raised when a user requests a report. Consumed by <c>GenerateReportHandler</c>, which calls
/// <c>IReportGenerator</c> and marks the report ready/failed.</summary>
public sealed record ReportRequestedDomainEvent(
    Guid ReportId,
    Guid UserId,
    ReportType ReportType,
    ReportFormat Format,
    string ParametersJson) : DomainEvent;
