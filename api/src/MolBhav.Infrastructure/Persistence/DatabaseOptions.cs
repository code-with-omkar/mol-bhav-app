namespace MolBhav.Infrastructure.Persistence;

public sealed class DatabaseOptions
{
    public const string SectionName = "Database";
    public const string ConnectionStringName = "MolBhav";

    public int MaxRetryCount { get; set; } = 3;

    public int CommandTimeoutSeconds { get; set; } = 30;

    /// <summary>Never enable outside Development: logs parameter values (PII).</summary>
    public bool EnableSensitiveDataLogging { get; set; }

    public bool EnableDetailedErrors { get; set; }
}
