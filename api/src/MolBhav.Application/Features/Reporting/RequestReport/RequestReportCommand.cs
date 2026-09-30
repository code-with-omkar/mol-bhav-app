using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Features.Reporting.RequestReport;

public sealed record RequestReportCommand(ReportType? ReportType, ReportFormat? Format, IReadOnlyDictionary<string, string>? Parameters)
    : ICommand<CreatedResponse>;
