using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Market.Admin.AddDistrict;

public sealed record AddDistrictCommand(Guid StateId, string Name) : ICommand<CreatedResponse>;
