using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Reporting;

namespace MolBhav.Application.Features.Reporting.DownloadReport;

/// <summary>A command rather than a query: serving the file also stamps <c>LastDownloadedAtUtc</c> on the report.</summary>
public sealed record DownloadReportCommand(Guid ReportId) : ICommand<ReportFileContent>;
