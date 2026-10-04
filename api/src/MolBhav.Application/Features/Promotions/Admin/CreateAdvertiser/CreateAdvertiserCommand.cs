using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Promotions.Admin.CreateAdvertiser;

public sealed record CreateAdvertiserCommand(string? Name, string? ContactName, string? ContactPhone, string? Gstin)
    : ICommand<CreatedResponse>;
