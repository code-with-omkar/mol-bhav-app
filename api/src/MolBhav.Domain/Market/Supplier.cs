using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Market;

/// <summary>
/// A regional construction-material supplier/hub (BRD §12: "Regional supplier / hub / district price benchmarks").
/// Deactivated, never deleted — price history keeps referring to it.
/// </summary>
public sealed class Supplier : AggregateRoot<Guid>, IAuditableEntity
{
    private Supplier(Guid id, MarketCode code, Guid districtId, string name, string? contactPhone)
        : base(id)
    {
        Code = code;
        DistrictId = districtId;
        Name = name;
        ContactPhone = contactPhone;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Supplier()
    {
        Code = null!;
        Name = string.Empty;
    }

    /// <summary>Globally unique — ingestion adapters map source supplier/hub names onto it.</summary>
    public MarketCode Code { get; private set; }

    public Guid DistrictId { get; private set; }

    public string Name { get; private set; }

    public string? ContactPhone { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>The caller (application layer) guarantees <paramref name="districtId"/> exists; the database FK is the backstop.</summary>
    public static Result<Supplier> Create(MarketCode code, Guid districtId, string? name, string? contactPhone)
    {
        ArgumentNullException.ThrowIfNull(code);

        var check = ValidateCommon(districtId, name, contactPhone);
        return check.IsFailure
            ? Result.Failure<Supplier>(check.Error)
            : new Supplier(Guid.CreateVersion7(), code, districtId, check.Value.Name, check.Value.ContactPhone);
    }

    public Result Update(Guid districtId, string? name, string? contactPhone, bool isActive)
    {
        var check = ValidateCommon(districtId, name, contactPhone);
        if (check.IsFailure)
        {
            return check.Error;
        }

        DistrictId = districtId;
        Name = check.Value.Name;
        ContactPhone = check.Value.ContactPhone;
        IsActive = isActive;
        return Result.Success();
    }

    private static Result<(string Name, string? ContactPhone)> ValidateCommon(Guid districtId, string? name, string? contactPhone)
    {
        if (districtId == Guid.Empty)
        {
            return Error.Validation("Supplier.DistrictRequired", "District is required.");
        }

        var nameResult = MarketRules.ValidateName(name, MarketRules.NameMaxLength, "Supplier", "Supplier");
        if (nameResult.IsFailure)
        {
            return Result.Failure<(string, string?)>(nameResult.Error);
        }

        var trimmedPhone = string.IsNullOrWhiteSpace(contactPhone) ? null : contactPhone.Trim();
        if (trimmedPhone is { Length: > MarketRules.ContactPhoneMaxLength })
        {
            return Error.Validation("Supplier.ContactPhoneTooLong", $"Contact phone cannot exceed {MarketRules.ContactPhoneMaxLength} characters.");
        }

        return (nameResult.Value, trimmedPhone);
    }
}
