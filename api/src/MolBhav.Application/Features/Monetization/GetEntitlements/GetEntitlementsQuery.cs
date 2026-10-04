using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Monetization.Models;

namespace MolBhav.Application.Features.Monetization.GetEntitlements;

public sealed record GetEntitlementsQuery : IQuery<EntitlementsResponse>;
