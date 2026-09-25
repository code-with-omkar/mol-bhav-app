using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Catalog.Admin.GetAdminUnits;

public sealed record GetAdminUnitsQuery : IQuery<IReadOnlyList<AdminUnitResponse>>;
