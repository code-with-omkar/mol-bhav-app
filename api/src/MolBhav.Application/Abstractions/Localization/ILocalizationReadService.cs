using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Localization.Models;

namespace MolBhav.Application.Abstractions.Localization;

/// <summary>Dapper-backed localization reads for the admin portal and the mobile app's data-driven strings (BRD §8/§18).</summary>
public interface ILocalizationReadService
{
    Task<PagedResult<AdminLocalizedTextResponse>> GetAdminTextsAsync(AdminLocalizedTextFilter filter, CancellationToken cancellationToken = default);

    Task<AdminLocalizedTextResponse?> GetAdminTextAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Every key resolved to one string for <paramref name="languageCode"/>, falling back to English when a key has
    /// no text in that language. <paramref name="keyPrefix"/> restricts to one namespace (e.g. <c>alerts.</c>) so the
    /// app can fetch only what a screen needs.
    /// </summary>
    Task<IReadOnlyDictionary<string, string>> GetTextsAsync(string languageCode, string? keyPrefix, CancellationToken cancellationToken = default);
}

public sealed record AdminLocalizedTextFilter(string? KeyPrefix, PageRequest Page);
