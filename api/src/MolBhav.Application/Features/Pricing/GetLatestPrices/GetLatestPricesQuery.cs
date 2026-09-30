using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.GetLatestPrices;

/// <summary>Comparison matrix for one product across mandis/suppliers (BRD §10).</summary>
public sealed record GetLatestPricesQuery(Guid ProductId, LocationKind? LocationKind, Guid? DistrictId, int Page, int PageSize)
    : IQuery<PagedResult<LatestPriceResponse>>;
