using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Ingestion.Models;

namespace MolBhav.Application.Features.Ingestion.Admin.RunCategoryIngestion;

/// <summary>
/// "Run all" for one procurement category: queues every active source of the category for one market day. Runs in the
/// background (one job per source, each in its own transaction) — a category can hold several slow government feeds.
/// </summary>
/// <param name="CategoryCode">e.g. <c>agriculture</c>, <c>construction</c>.</param>
/// <param name="RequestedByUserId">The admin who asked for the run (recorded on each job).</param>
/// <param name="AsOfDate">Market day to pull (IST); null = the default lagged day the scheduler uses.</param>
public sealed record RunCategoryIngestionCommand(string CategoryCode, Guid RequestedByUserId, DateOnly? AsOfDate = null)
    : ICommand<CategoryRunQueuedResponse>;
