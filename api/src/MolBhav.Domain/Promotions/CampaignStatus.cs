namespace MolBhav.Domain.Promotions;

public enum CampaignStatus
{
    /// <summary>Being set up; never served.</summary>
    Draft = 0,

    /// <summary>Served while inside its schedule.</summary>
    Active = 1,

    /// <summary>Temporarily stopped by an admin; can be re-activated.</summary>
    Paused = 2,

    /// <summary>Finished for good (sold period over, or cancelled). Terminal.</summary>
    Ended = 3,
}
