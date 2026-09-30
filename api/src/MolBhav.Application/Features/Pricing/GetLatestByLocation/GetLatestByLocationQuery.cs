using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Pricing.Models;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Pricing.GetLatestByLocation;

/// <summary>Browse-by-mandi: latest price per product/variant at one mandi or supplier.</summary>
public sealed record GetLatestByLocationQuery(LocationKind LocationKind, Guid LocationId, int Page, int PageSize)
    : IQuery<PagedResult<LocationLatestPriceResponse>>;
