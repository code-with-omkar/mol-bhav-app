using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Promotions.Models;

namespace MolBhav.Application.Features.Promotions.Admin.GetAdvertisers;

public sealed record GetAdvertisersQuery : IQuery<IReadOnlyList<AdvertiserResponse>>;
