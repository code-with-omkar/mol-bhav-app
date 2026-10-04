using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Monetization.Models;

namespace MolBhav.Application.Features.Monetization.GetAdUnlockSession;

public sealed record GetAdUnlockSessionQuery(Guid SessionId) : IQuery<AdUnlockSessionResponse>;
