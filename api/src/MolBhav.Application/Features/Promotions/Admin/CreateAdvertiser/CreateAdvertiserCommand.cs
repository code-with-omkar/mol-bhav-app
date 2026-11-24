using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Promotions.Admin.CreateAdvertiser;

public sealed record CreateAdvertiserCommand(string? Name, string? ContactName, string? ContactPhone, string? Gstin)
    : ICommand<CreatedResponse>, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Advertiser.Create";

    // A business name, not a person: fine to keep. Contact details and GST number are not copied into the log.
    string? IAuditedCommand.AuditTarget => Name?.Trim();

    string IAuditedCommand.AuditSummary => "Added an advertiser";
}
