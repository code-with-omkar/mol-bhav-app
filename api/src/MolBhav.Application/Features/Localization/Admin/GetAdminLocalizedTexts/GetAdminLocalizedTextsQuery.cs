using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Localization.Models;

namespace MolBhav.Application.Features.Localization.Admin.GetAdminLocalizedTexts;

public sealed record GetAdminLocalizedTextsQuery(string? KeyPrefix, int Page, int PageSize)
    : IQuery<PagedResult<AdminLocalizedTextResponse>>;
