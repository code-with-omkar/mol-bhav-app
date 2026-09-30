using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Features.Market.Admin.GetAdminMandis;

public sealed record GetAdminMandisQuery(Guid? DistrictId, string? Search, bool? IsActive, int Page, int PageSize)
    : IQuery<PagedResult<AdminMandiResponse>>;
