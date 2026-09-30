using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Market;

/// <summary>
/// An Indian state/UT (BRD §19 Locations): Maharashtra, Gujarat, ... Deactivated, never deleted — mandis/suppliers
/// keep referencing its districts.
/// </summary>
public sealed class State : AggregateRoot<Guid>, IAuditableEntity
{
    private readonly List<District> _districts = [];

    private State(Guid id, string name, string code)
        : base(id)
    {
        Name = name;
        Code = code;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private State()
    {
        Name = string.Empty;
        Code = string.Empty;
    }

    /// <summary>Globally unique display name.</summary>
    public string Name { get; private set; }

    /// <summary>Short admin-facing code (e.g. <c>MH</c>), globally unique.</summary>
    public string Code { get; private set; }

    public bool IsActive { get; private set; }

    public IReadOnlyCollection<District> Districts => _districts.AsReadOnly();

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<State> Create(string? name, string? code)
    {
        var nameResult = MarketRules.ValidateName(name, MarketRules.StateNameMaxLength, "State", "State");
        if (nameResult.IsFailure)
        {
            return Result.Failure<State>(nameResult.Error);
        }

        var codeResult = NormaliseCode(code);
        if (codeResult.IsFailure)
        {
            return Result.Failure<State>(codeResult.Error);
        }

        return new State(Guid.CreateVersion7(), nameResult.Value, codeResult.Value);
    }

    public Result Update(string? name, bool isActive)
    {
        var nameResult = MarketRules.ValidateName(name, MarketRules.StateNameMaxLength, "State", "State");
        if (nameResult.IsFailure)
        {
            return nameResult.Error;
        }

        Name = nameResult.Value;
        IsActive = isActive;
        return Result.Success();
    }

    public Result<District> AddDistrict(string? name)
    {
        var nameResult = MarketRules.ValidateName(name, MarketRules.DistrictNameMaxLength, "District", "District");
        if (nameResult.IsFailure)
        {
            return Result.Failure<District>(nameResult.Error);
        }

        if (_districts.Any(d => string.Equals(d.Name, nameResult.Value, StringComparison.OrdinalIgnoreCase)))
        {
            return Error.Conflict("District.NameTaken", $"District '{nameResult.Value}' already exists in '{Name}'.");
        }

        var district = District.Create(Id, nameResult.Value);
        _districts.Add(district);
        return district;
    }

    public Result UpdateDistrict(Guid districtId, string? name, bool isActive)
    {
        var district = _districts.Find(d => d.Id == districtId);
        if (district is null)
        {
            return Error.NotFound("District.NotFound", "District not found in this state.");
        }

        var nameResult = MarketRules.ValidateName(name, MarketRules.DistrictNameMaxLength, "District", "District");
        if (nameResult.IsFailure)
        {
            return nameResult.Error;
        }

        district.Update(nameResult.Value, isActive);
        return Result.Success();
    }

    /// <summary>2–10 uppercase letters/digits, e.g. <c>MH</c>.</summary>
    private static Result<string> NormaliseCode(string? code)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return Error.Validation("State.CodeRequired", "State code is required.");
        }

        var normalised = code.Trim().ToUpperInvariant();
        return normalised.Length <= MarketRules.StateCodeMaxLength
            ? normalised
            : Error.Validation("State.CodeTooLong", $"State code cannot exceed {MarketRules.StateCodeMaxLength} characters.");
    }
}
