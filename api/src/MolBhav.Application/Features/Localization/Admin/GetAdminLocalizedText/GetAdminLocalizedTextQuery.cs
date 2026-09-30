using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Localization.Models;

namespace MolBhav.Application.Features.Localization.Admin.GetAdminLocalizedText;

public sealed record GetAdminLocalizedTextQuery(Guid LocalizedTextId) : IQuery<AdminLocalizedTextResponse>;
