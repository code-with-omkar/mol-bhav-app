namespace MolBhav.Domain.Identity;

/// <summary>
/// Platform role. <see cref="Admin"/> manages reference data (catalog, markets, sources — BRD §22). There is deliberately
/// no self-service way to become admin: it is granted out-of-band (see README, "Granting admin").
/// </summary>
public enum UserRole
{
    User = 0,
    Admin = 1,
}
