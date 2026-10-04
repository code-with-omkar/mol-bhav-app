using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Promotions;

/// <summary>A business that buys sponsored placements (a building-material dealer, a seed company…).</summary>
public sealed class Advertiser : AggregateRoot<Guid>, IAuditableEntity
{
    public const int NameMaxLength = 120;
    public const int ContactMaxLength = 120;
    public const int PhoneMaxLength = 20;
    public const int GstinLength = 15;

    private Advertiser(Guid id, string name, string? contactName, string? contactPhone, string? gstin)
        : base(id)
    {
        Name = name;
        ContactName = contactName;
        ContactPhone = contactPhone;
        Gstin = gstin;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Advertiser()
    {
        Name = string.Empty;
    }

    public string Name { get; private set; }

    public string? ContactName { get; private set; }

    public string? ContactPhone { get; private set; }

    /// <summary>GST number, needed on the invoice for a sold placement.</summary>
    public string? Gstin { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<Advertiser> Create(string? name, string? contactName, string? contactPhone, string? gstin)
    {
        var validated = Validate(name, contactName, contactPhone, gstin);
        if (validated.IsFailure)
        {
            return Result.Failure<Advertiser>(validated.Error);
        }

        var (n, cn, cp, g) = validated.Value;
        return new Advertiser(Guid.CreateVersion7(), n, cn, cp, g);
    }

    public Result Update(string? name, string? contactName, string? contactPhone, string? gstin)
    {
        var validated = Validate(name, contactName, contactPhone, gstin);
        if (validated.IsFailure)
        {
            return validated.Error;
        }

        (Name, ContactName, ContactPhone, Gstin) = validated.Value;
        return Result.Success();
    }

    private static Result<(string Name, string? ContactName, string? ContactPhone, string? Gstin)> Validate(
        string? name, string? contactName, string? contactPhone, string? gstin)
    {
        var n = name?.Trim() ?? string.Empty;
        if (n.Length is 0 or > NameMaxLength)
        {
            return Error.Validation("Advertiser.NameInvalid", $"Name is required and at most {NameMaxLength} characters.");
        }

        var cn = Optional(contactName);
        if (cn is { Length: > ContactMaxLength })
        {
            return Error.Validation("Advertiser.ContactInvalid", $"Contact name is at most {ContactMaxLength} characters.");
        }

        var cp = Optional(contactPhone);
        if (cp is { Length: > PhoneMaxLength })
        {
            return Error.Validation("Advertiser.PhoneInvalid", $"Phone is at most {PhoneMaxLength} characters.");
        }

        var g = Optional(gstin)?.ToUpperInvariant();
        if (g is not null && (g.Length != GstinLength || !g.All(char.IsAsciiLetterOrDigit)))
        {
            return Error.Validation("Advertiser.GstinInvalid", $"GSTIN is {GstinLength} letters and digits.");
        }

        return (n, cn, cp, g);
    }

    private static string? Optional(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
