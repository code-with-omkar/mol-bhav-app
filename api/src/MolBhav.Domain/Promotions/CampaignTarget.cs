using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Promotions;

/// <summary>
/// Who sees a campaign: users with this procurement category, in <see cref="StateId"/> or (when null) anywhere.
/// Part of the <see cref="Campaign"/> aggregate; one row per category × state, which keeps targeting in 3NF.
/// </summary>
public sealed class CampaignTarget : Entity<Guid>
{
    internal CampaignTarget(Guid id, string categoryCode, Guid? stateId)
        : base(id)
    {
        CategoryCode = categoryCode;
        StateId = stateId;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private CampaignTarget()
    {
        CategoryCode = string.Empty;
    }

    public string CategoryCode { get; private set; }

    /// <summary>Market-master state; <c>null</c> targets every state.</summary>
    public Guid? StateId { get; private set; }
}
