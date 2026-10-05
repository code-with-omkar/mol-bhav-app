namespace MolBhav.Infrastructure.Persistence;

/// <summary>
/// One PostgreSQL schema per module (modular monolith): logical isolation, one database, one transaction scope.
/// Cross-schema FKs are allowed only towards shared reference data (catalog, market); modules never write
/// into another module's schema.
/// </summary>
public static class Schemas
{
    /// <summary>Default schema + EF migrations history.</summary>
    public const string Platform = "platform";

    /// <summary>Users, profiles, OTP challenges, refresh tokens.</summary>
    public const string Identity = "identity";

    /// <summary>Plans, subscriptions, entitlements.</summary>
    public const string Billing = "billing";

    /// <summary>Procurement categories, sub-categories, products, variants, units of measure.</summary>
    public const string Catalog = "catalog";

    /// <summary>Locations, markets, mandis, suppliers, hubs.</summary>
    public const string Market = "market";

    /// <summary>Price sources, price records, price history.</summary>
    public const string Pricing = "pricing";

    /// <summary>Ingestion jobs and errors.</summary>
    public const string Ingestion = "ingestion";

    /// <summary>Watchlists and watchlist items.</summary>
    public const string Watchlist = "watchlist";

    /// <summary>Alert rules and triggered alerts.</summary>
    public const string Alerting = "alerting";

    /// <summary>Procurement requirements, opportunities, cost components.</summary>
    public const string Procurement = "procurement";

    /// <summary>Push/WhatsApp notifications and delivery status.</summary>
    public const string Notification = "notification";

    /// <summary>Generated reports and exports.</summary>
    public const string Reporting = "reporting";

    /// <summary>Localized texts for data-driven terminology.</summary>
    public const string Localization = "localization";

    /// <summary>Support tickets and their message threads.</summary>
    public const string Support = "support";

    /// <summary>Free-tier limits: rewarded-ad unlock sessions, verified ad views, earned feature grants.</summary>
    public const string Monetization = "monetization";

    /// <summary>Direct-sold sponsored campaigns: advertisers, campaigns, targets, daily delivery counts.</summary>
    public const string Promotions = "promotions";

    /// <summary>Per-user IMD weather forecasts (replaced daily, no history).</summary>
    public const string Weather = "weather";

    /// <summary>Transactional outbox.</summary>
    public const string Messaging = "messaging";
}
