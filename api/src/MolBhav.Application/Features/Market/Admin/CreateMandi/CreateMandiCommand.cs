using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Market.Admin.CreateMandi;

public sealed record CreateMandiCommand(string Code, Guid DistrictId, string Name) : ICommand<CreatedResponse>;
