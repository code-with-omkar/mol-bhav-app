using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Market;

/// <summary>
/// An APMC mandi (BRD §11): the agriculture pricing location — price records reference it. Deactivated, never
/// deleted — price history keeps referring to it.
/// </summary>
public sealed class Mandi : AggregateRoot<Guid>, IAuditableEntity
{
    private Mandi(Guid id, MarketCode code, Guid districtId, string name)
        : base(id)
    {
        Code = code;
        DistrictId = districtId;
        Name = name;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private Mandi()
    {
        Code = null!;
        Name = string.Empty;
    }

    /// <summary>Globally unique — ingestion adapters map source mandi names onto it.</summary>
    public MarketCode Code { get; private set; }

    public Guid DistrictId { get; private set; }

    public string Name { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    /// <summary>The caller (application layer) guarantees <paramref name="districtId"/> exists; the database FK is the backstop.</summary>
    public static Result<Mandi> Create(MarketCode code, Guid districtId, string? name)
    {
        ArgumentNullException.ThrowIfNull(code);

        var check = ValidateCommon(districtId, name);
        return check.IsFailure
            ? Result.Failure<Mandi>(check.Error)
            : new Mandi(Guid.CreateVersion7(), code, districtId, check.Value);
    }

    public Result Update(Guid districtId, string? name, bool isActive)
    {
        var check = ValidateCommon(districtId, name);
        if (check.IsFailure)
        {
            return check.Error;
        }

        DistrictId = districtId;
        Name = check.Value;
        IsActive = isActive;
        return Result.Success();
    }

    private static Result<string> ValidateCommon(Guid districtId, string? name)
    {
        if (districtId == Guid.Empty)
        {
            return Error.Validation("Mandi.DistrictRequired", "District is required.");
        }

        return MarketRules.ValidateName(name, MarketRules.NameMaxLength, "Mandi", "Mandi");
    }
}
