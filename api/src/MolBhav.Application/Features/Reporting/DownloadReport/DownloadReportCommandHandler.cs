using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Reporting;

namespace MolBhav.Application.Features.Reporting.DownloadReport;

internal sealed class DownloadReportCommandHandler(
    IReportRepository reports,
    IReportFileStore files,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : ICommandHandler<DownloadReportCommand, ReportFileContent>
{
    public async Task<Result<ReportFileContent>> Handle(DownloadReportCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var report = await reports.GetByIdAsync(request.ReportId, cancellationToken);
        if (report is null || report.UserId != userId)
        {
            // Same 404 whether it's someone else's report or doesn't exist — never reveal other users' data.
            return Error.NotFound("Report.NotFound", "Report not found.");
        }

        if (report.Status != ReportStatus.Ready)
        {
            return Error.Conflict("Report.NotReady", report.Status == ReportStatus.Pending
                ? "The report is still being generated."
                : "The report failed to generate.");
        }

        var file = await files.GetAsync(request.ReportId, userId, cancellationToken);
        if (file is null)
        {
            return Error.NotFound("Report.FileNotFound", "The report file is no longer available.");
        }

        report.MarkDownloaded(timeProvider.GetUtcNow());
        return file;
    }
}
