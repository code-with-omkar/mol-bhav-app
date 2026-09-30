using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Market;

/// <summary>
/// A district inside a <see cref="State"/> (BRD §11: "APMC mandi master with district, state, and localized names").
/// Part of the <see cref="State"/> aggregate: created and changed only through it. Mandis/suppliers reference it by id.
/// </summary>
public sealed class District : Entity<Guid>, IAuditableEntity
{
    private District(Guid id, Guid stateId, string name)
        : base(id)
    {
        StateId = stateId;
        Name = name;
        IsActive = true;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private District()
    {
        Name = string.Empty;
    }

    public Guid StateId { get; private set; }

    /// <summary>Unique within its state.</summary>
    public string Name { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    internal static District Create(Guid stateId, string name) => new(Guid.CreateVersion7(), stateId, name);

    internal void Update(string name, bool isActive)
    {
        Name = name;
        IsActive = isActive;
    }
}
