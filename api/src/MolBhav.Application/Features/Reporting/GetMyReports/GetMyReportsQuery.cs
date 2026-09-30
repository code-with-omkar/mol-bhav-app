using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Reporting.Models;

namespace MolBhav.Application.Features.Reporting.GetMyReports;

public sealed record GetMyReportsQuery(int Page, int PageSize) : IQuery<PagedResult<ReportResponse>>;
