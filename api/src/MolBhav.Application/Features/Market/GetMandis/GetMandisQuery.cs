using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Features.Market.GetMandis;

/// <summary>Mandis, optionally narrowed to a district and/or a name search.</summary>
public sealed record GetMandisQuery(Guid? DistrictId, string? Search, int Page, int PageSize) : IQuery<PagedResult<MandiResponse>>;
