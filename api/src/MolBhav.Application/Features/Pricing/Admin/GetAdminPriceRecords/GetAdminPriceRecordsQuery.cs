using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.Admin.GetAdminPriceRecords;

public sealed record GetAdminPriceRecordsQuery(
    Guid? ProductId,
    LocationKind? LocationKind,
    Guid? LocationId,
    DateOnly? FromDate,
    DateOnly? ToDate,
    bool? IsVoided,
    int Page,
    int PageSize) : IQuery<PagedResult<AdminPriceRecordResponse>>;
