using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Features.Market.GetStates;

/// <summary>Active states — the app's state picker for location filters.</summary>
public sealed record GetStatesQuery : IQuery<IReadOnlyList<StateResponse>>;
