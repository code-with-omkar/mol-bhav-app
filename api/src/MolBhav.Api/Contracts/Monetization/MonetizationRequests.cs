using MolBhav.Domain.Monetization;

namespace MolBhav.Api.Contracts.Monetization;

public sealed record StartAdUnlockRequest(MonetizedFeature? Feature);
