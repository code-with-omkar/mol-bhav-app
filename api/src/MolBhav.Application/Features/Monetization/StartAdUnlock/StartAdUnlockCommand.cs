using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Monetization.Models;
using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Features.Monetization.StartAdUnlock;

public sealed record StartAdUnlockCommand(MonetizedFeature? Feature) : ICommand<AdUnlockSessionResponse>;
