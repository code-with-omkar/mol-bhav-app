using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Domain.Pricing;

/// <summary>A data source feeding price records (BRD §9): Agmarknet, data.gov.in, CPWD schedule rates, a manual admin entry. Deactivated, never deleted — price records reference it.</summary>
public sealed class PriceSource : AggregateRoot<Guid>, IAuditableEntity
{
    private PriceSource(Guid id, string code, string name)
        : base(id)
    {
        Code = code;
        Name = name;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private PriceSource()
    {
        Code = string.Empty;
        Name = string.Empty;
    }

    /// <summary>Globally unique, immutable — ingestion adapters and price records reference it (e.g. <c>agmarknet</c>).</summary>
    public string Code { get; private set; }

    public string Name { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static Result<PriceSource> Create(string? code, string? name)
    {
        var codeResult = PricingRules.ValidateSourceCode(code);
        if (codeResult.IsFailure)
        {
            return Result.Failure<PriceSource>(codeResult.Error);
        }

        var nameResult = PricingRules.ValidateSourceName(name);
        return nameResult.IsFailure
            ? Result.Failure<PriceSource>(nameResult.Error)
            : new PriceSource(Guid.CreateVersion7(), codeResult.Value, nameResult.Value);
    }

    public Result Update(string? name, bool isActive)
    {
        var nameResult = PricingRules.ValidateSourceName(name);
        if (nameResult.IsFailure)
        {
            return nameResult.Error;
        }

        Name = nameResult.Value;
        IsActive = isActive;
        return Result.Success();
    }
}
