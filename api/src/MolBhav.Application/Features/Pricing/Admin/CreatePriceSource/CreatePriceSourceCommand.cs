using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Pricing.Admin.CreatePriceSource;

public sealed record CreatePriceSourceCommand(string Code, string Name) : ICommand<CreatedResponse>;
