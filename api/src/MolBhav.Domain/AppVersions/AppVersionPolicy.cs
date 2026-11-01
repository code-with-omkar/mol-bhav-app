using System.Text.RegularExpressions;
using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.AppVersions;

/// <summary>
/// The oldest app version still allowed to run. Older builds show an "update required" page with a link to update
/// from. A single row for the whole app, edited in place; no minimum means every version may run.
/// </summary>
public sealed partial class AppVersionPolicy : AggregateRoot<Guid>, IAuditableEntity
{
    public const int VersionMaxLength = 20;
    public const int UrlMaxLength = 500;

    private AppVersionPolicy(Guid id, string? minimumVersion, string? updateUrl)
        : base(id)
    {
        MinimumVersion = minimumVersion;
        UpdateUrl = updateUrl;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private AppVersionPolicy()
    {
    }

    /// <summary>The oldest allowed version as <c>major.minor.patch</c>; null when there is no minimum.</summary>
    public string? MinimumVersion { get; private set; }

    /// <summary>Where users go to update (a store page); null when none is set.</summary>
    public string? UpdateUrl { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<AppVersionPolicy> Create(string? minimumVersion, string? updateUrl)
    {
        var validated = Validate(minimumVersion, updateUrl);
        if (validated.IsFailure)
        {
            return validated.Error;
        }

        return new AppVersionPolicy(Guid.CreateVersion7(), validated.Value.Version, validated.Value.Url);
    }

    public Result Update(string? minimumVersion, string? updateUrl)
    {
        var validated = Validate(minimumVersion, updateUrl);
        if (validated.IsFailure)
        {
            return validated.Error;
        }

        MinimumVersion = validated.Value.Version;
        UpdateUrl = validated.Value.Url;
        return Result.Success();
    }

    /// <summary>
    /// "1", "1.2" and "1.2.3" are accepted and written as <c>1.2.3</c>; anything else (letters, a build suffix) is
    /// refused, so the app never has to guess what a stored version means.
    /// </summary>
    private static Result<(string? Version, string? Url)> Validate(string? minimumVersion, string? updateUrl)
    {
        string? version = null;
        var text = minimumVersion?.Trim();
        if (!string.IsNullOrEmpty(text))
        {
            if (text.Length > VersionMaxLength || !VersionPattern().IsMatch(text))
            {
                return Error.Validation("AppVersion.VersionInvalid", "Use a version like 1.2.0 (numbers separated by dots).");
            }

            var parts = text.Split('.').Select(p => int.TryParse(p, out var n) ? n : -1).ToList();
            if (parts.Any(n => n < 0))
            {
                return Error.Validation("AppVersion.VersionInvalid", "Use a version like 1.2.0 (numbers separated by dots).");
            }

            while (parts.Count < 3)
            {
                parts.Add(0);
            }

            version = string.Join('.', parts);
        }

        string? url = null;
        var link = updateUrl?.Trim();
        if (!string.IsNullOrEmpty(link))
        {
            if (link.Length > UrlMaxLength
                || !Uri.TryCreate(link, UriKind.Absolute, out var uri)
                || (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp))
            {
                return Error.Validation("AppVersion.UrlInvalid", "The update link must be a web address starting with https://.");
            }

            url = link;
        }

        return (version, url);
    }

    [GeneratedRegex(@"^\d{1,6}(\.\d{1,6}){0,2}$")]
    private static partial Regex VersionPattern();
}
