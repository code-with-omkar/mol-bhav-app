using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Market.Admin.CreateSupplier;

public sealed record CreateSupplierCommand(string Code, Guid DistrictId, string Name, string? ContactPhone) : ICommand<CreatedResponse>;
