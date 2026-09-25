using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.UpdateUnit;

/// <summary>Code, dimension and conversion factor are immutable (recorded prices depend on them); a correction is a new unit.</summary>
public sealed record UpdateUnitCommand(
    Guid UnitId,
    string Symbol,
    bool? IsActive,
    IReadOnlyCollection<TranslationInput> Translations) : ICommand;
