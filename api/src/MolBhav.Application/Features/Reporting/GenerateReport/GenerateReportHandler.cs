using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Events;
using MolBhav.Application.Abstractions.Reporting;
using MolBhav.Domain.Reporting.Events;

namespace MolBhav.Application.Features.Reporting.GenerateReport;

/// <summary>Reacts to a report request by calling <see cref="IReportGenerator"/> and persisting the outcome. Runs
/// outside <c>UnitOfWorkBehavior</c> (dispatched from the outbox, not through MediatR), so it commits its own unit of work.</summary>
internal sealed class GenerateReportHandler(
    IReportRepository reports,
    IReportGenerator generator,
    IUnitOfWork unitOfWork,
    TimeProvider timeProvider) : IDomainEventHandler<ReportRequestedDomainEvent>
{
    public async Task HandleAsync(ReportRequestedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var report = await reports.GetByIdAsync(domainEvent.ReportId, cancellationToken);
        if (report is null)
        {
            return;
        }

        var outcome = await generator.GenerateAsync(
            new ReportGenerationRequest(
                domainEvent.ReportId, domainEvent.UserId, domainEvent.ReportType, domainEvent.Format, domainEvent.ParametersJson),
            cancellationToken);

        var completedAtUtc = timeProvider.GetUtcNow();
        if (outcome.IsSuccess)
        {
            report.MarkReady(outcome.DownloadUrl!, completedAtUtc);
        }
        else
        {
            report.MarkFailed(outcome.FailureReason ?? "Report generation failed.", completedAtUtc);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
