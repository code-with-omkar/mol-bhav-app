using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Market.Admin.UpdateDistrict;

public sealed record UpdateDistrictCommand(Guid StateId, Guid DistrictId, string Name, bool? IsActive) : ICommand;
