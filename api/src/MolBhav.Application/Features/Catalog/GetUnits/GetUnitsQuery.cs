using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.GetUnits;

/// <summary>Active units with conversion factors — the app uses them for quantity pickers and client-side unit conversion.</summary>
public sealed record GetUnitsQuery : IQuery<IReadOnlyList<UnitResponse>>;
