namespace MolBhav.Domain.Monetization;

public enum AdUnlockSessionStatus
{
    /// <summary>Waiting for verified ad views. Effectively expired once <see cref="AdUnlockSession.ExpiresAtUtc"/> passes.</summary>
    Pending = 0,

    /// <summary>Enough verified views arrived (or no ad could be served); the grant has been issued.</summary>
    Granted = 1,
}
