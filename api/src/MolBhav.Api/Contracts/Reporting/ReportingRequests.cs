using MolBhav.Domain.Reporting;

namespace MolBhav.Api.Contracts.Reporting;

public sealed record RequestReportRequest(ReportType? ReportType, ReportFormat? Format, IReadOnlyDictionary<string, string>? Parameters);
