using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Features.Market.GetDistricts;

/// <summary>Active districts of one state.</summary>
public sealed record GetDistrictsQuery(Guid StateId) : IQuery<IReadOnlyList<DistrictResponse>>;
