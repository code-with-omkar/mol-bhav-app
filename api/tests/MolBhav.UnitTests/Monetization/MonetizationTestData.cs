using MolBhav.Domain.Monetization;

namespace MolBhav.UnitTests.Monetization;

internal static class MonetizationTestData
{
    /// <summary>10:30 IST — well inside one IST day, so "today" caps are unambiguous.</summary>
    public static readonly DateTimeOffset Now = new(2026, 10, 3, 5, 0, 0, TimeSpan.Zero);

    public static readonly Guid UserId = Guid.CreateVersion7();

    public static FreeTierLimits Limits() => new(
        new SlotAllowance(Included: 10, PerUnlock: 5, Maximum: 25, AdsPerUnlock: 1),
        new SlotAllowance(Included: 5, PerUnlock: 2, Maximum: 11, AdsPerUnlock: 1),
        new ReportAllowance(AdsPerUnlock: 2, UnlocksPerDay: 2, UnlockLifetime: TimeSpan.FromHours(24)),
        NoFillGrantsPerDay: 1,
        UnlockSessionLifetime: TimeSpan.FromMinutes(30));

    public static AdUnlockSession Session(MonetizedFeature feature, int adsRequired) =>
        AdUnlockSession.Start(UserId, feature, adsRequired, Now, TimeSpan.FromMinutes(30)).Value;
}
