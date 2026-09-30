using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Market.Admin.CreateState;

public sealed record CreateStateCommand(string Name, string Code) : ICommand<CreatedResponse>;
