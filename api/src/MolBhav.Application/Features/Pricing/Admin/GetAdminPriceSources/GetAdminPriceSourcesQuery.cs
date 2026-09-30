using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Pricing.Models;

namespace MolBhav.Application.Features.Pricing.Admin.GetAdminPriceSources;

public sealed record GetAdminPriceSourcesQuery : IQuery<IReadOnlyList<AdminPriceSourceResponse>>;
