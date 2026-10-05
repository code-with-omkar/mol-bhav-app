using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Ingestion;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Application.Features.Ingestion.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Ingestion;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Ingestion.Admin.RunCategoryIngestion;

internal sealed class RunCategoryIngestionCommandHandler(
    IProcurementCategoryRepository categories,
    IPriceSourceRepository sources,
    IIngestionBackfillQueue queue,
    TimeProvider timeProvider) : ICommandHandler<RunCategoryIngestionCommand, CategoryRunQueuedResponse>
{
    public async Task<Result<CategoryRunQueuedResponse>> Handle(RunCategoryIngestionCommand request, CancellationToken cancellationToken)
    {
        var code = ProcurementCategoryCode.Create(request.CategoryCode);
        if (code.IsFailure)
        {
            return Result.Failure<CategoryRunQueuedResponse>(code.Error);
        }

        var categoryId = await categories.GetActiveIdByCodeAsync(code.Value, cancellationToken);
        if (categoryId is null)
        {
            return Error.NotFound("Category.NotFound", $"No active category with code '{code.Value.Value}'.");
        }

        var now = timeProvider.GetUtcNow();
        var asOfDate = request.AsOfDate ?? IngestionDates.DefaultAsOf(now);
        if (asOfDate > IngestionDates.TodayIst(now))
        {
            return Error.Validation("Ingestion.FutureDate", "asOfDate cannot be in the future (IST).");
        }

        var sourceIds = await sources.GetActiveIdsByCategoryAsync(categoryId.Value, cancellationToken);
        if (sourceIds.Count == 0)
        {
            return Error.Validation("Ingestion.NoActiveSources", $"Category '{code.Value.Value}' has no active price sources.");
        }

        if (!queue.TryEnqueue(new IngestionBackfillRequest(sourceIds, request.RequestedByUserId, [asOfDate])))
        {
            return Error.Conflict("Ingestion.BackfillBusy", "Too many runs are waiting. Try again when the current ones finish.");
        }

        return new CategoryRunQueuedResponse(code.Value.Value, sourceIds.Count, asOfDate);
    }
}
