using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Promotions.Admin.UpdateAdvertiser;

public sealed record UpdateAdvertiserCommand(Guid AdvertiserId, string? Name, string? ContactName, string? ContactPhone, string? Gstin)
    : ICommand;
