using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Catalog;

namespace MolBhav.Application.Features.Catalog.Admin.CreateUnit;

/// <summary><paramref name="ToBaseFactor"/>: base units per one of this unit (kg for mass, m³ for volume, piece for count, m, m²).</summary>
public sealed record CreateUnitCommand(
    string Code,
    string Symbol,
    MeasureDimension? Dimension,
    decimal? ToBaseFactor,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand<CreatedResponse>;
