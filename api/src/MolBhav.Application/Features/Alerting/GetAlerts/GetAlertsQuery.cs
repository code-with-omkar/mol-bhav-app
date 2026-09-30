using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Alerting.Models;

namespace MolBhav.Application.Features.Alerting.GetAlerts;

public sealed record GetAlertsQuery(int Page, int PageSize) : IQuery<PagedResult<AlertResponse>>;
