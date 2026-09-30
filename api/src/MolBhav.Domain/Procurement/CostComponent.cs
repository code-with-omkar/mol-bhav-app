using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Procurement;

/// <summary>
/// An admin-configured cost line applied on top of price × quantity when computing a <see cref="ProcurementOpportunity"/>
/// (BRD §17/§25 — freight, handling, taxes/charges, supplier terms). Deactivated, never deleted — historical
/// opportunities keep whatever components were active when they were computed.
/// </summary>
public sealed class CostComponent : AggregateRoot<Guid>, IAuditableEntity
{
    public const int CodeMaxLength = 32;
    public const int NameMaxLength = 100;

    private CostComponent(Guid id, string code, string name, CostComponentType componentType, decimal value)
        : base(id)
    {
        Code = code;
        Name = name;
        ComponentType = componentType;
        Value = value;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private CostComponent()
    {
        Code = string.Empty;
        Name = string.Empty;
    }

    /// <summary>Globally unique, immutable.</summary>
    public string Code { get; private set; }

    public string Name { get; private set; }

    public CostComponentType ComponentType { get; private set; }

    /// <summary>A percentage (e.g. 2 = 2%) when <see cref="ComponentType"/> is <see cref="CostComponentType.Percentage"/>, otherwise a flat currency amount.</summary>
    public decimal Value { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<CostComponent> Create(string? code, string? name, CostComponentType componentType, decimal value)
    {
        var codeResult = ValidateCode(code);
        if (codeResult.IsFailure)
        {
            return Result.Failure<CostComponent>(codeResult.Error);
        }

        var nameResult = ValidateName(name);
        if (nameResult.IsFailure)
        {
            return Result.Failure<CostComponent>(nameResult.Error);
        }

        var valueResult = ValidateValue(componentType, value);
        return valueResult.IsFailure
            ? Result.Failure<CostComponent>(valueResult.Error)
            : new CostComponent(Guid.CreateVersion7(), codeResult.Value, nameResult.Value, componentType, value);
    }

    public Result Update(string? name, decimal value, bool isActive)
    {
        var nameResult = ValidateName(name);
        if (nameResult.IsFailure)
        {
            return nameResult.Error;
        }

        var valueResult = ValidateValue(ComponentType, value);
        if (valueResult.IsFailure)
        {
            return valueResult.Error;
        }

        Name = nameResult.Value;
        Value = value;
        IsActive = isActive;
        return Result.Success();
    }

    /// <summary>Applies this component on top of a computed base cost (price × quantity).</summary>
    public decimal Apply(decimal baseCost) => ComponentType switch
    {
        CostComponentType.Percentage => baseCost * Value / 100m,
        CostComponentType.Fixed => Value,
        _ => 0m,
    };

    private static Result<string> ValidateCode(string? code)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return Error.Validation("CostComponent.CodeRequired", "Code is required.");
        }

        var trimmed = code.Trim();
        return trimmed.Length <= CodeMaxLength
            ? trimmed
            : Error.Validation("CostComponent.CodeTooLong", $"Code must be at most {CodeMaxLength} characters.");
    }

    private static Result<string> ValidateName(string? name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return Error.Validation("CostComponent.NameRequired", "Name is required.");
        }

        var trimmed = name.Trim();
        return trimmed.Length <= NameMaxLength
            ? trimmed
            : Error.Validation("CostComponent.NameTooLong", $"Name must be at most {NameMaxLength} characters.");
    }

    private static Result ValidateValue(CostComponentType componentType, decimal value)
    {
        if (componentType == CostComponentType.Percentage && (value < 0 || value > 100))
        {
            return Error.Validation("CostComponent.InvalidPercentage", "A percentage component must be between 0 and 100.");
        }

        return value < 0
            ? Error.Validation("CostComponent.InvalidValue", "Value must not be negative.")
            : Result.Success();
    }
}
