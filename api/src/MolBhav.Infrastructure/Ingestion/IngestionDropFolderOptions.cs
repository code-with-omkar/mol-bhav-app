namespace MolBhav.Infrastructure.Ingestion;

/// <summary>
/// Drop-folder importer: CSVs placed in <c>&lt;Path&gt;/&lt;price source code&gt;/</c> (e.g. <c>ingestion-drop/agmarknet/</c>) are imported
/// exactly like an admin upload, then moved to <c>&lt;Path&gt;/processed</c> or <c>&lt;Path&gt;/failed</c>. The fallback for
/// when a source's API is down and its portal export has to be downloaded by hand.
/// </summary>
public sealed class IngestionDropFolderOptions
{
    public const string SectionName = "IngestionDropFolder";

    /// <summary>Master switch. Off by default — anyone who can write to <see cref="Path"/> can feed prices in.</summary>
    public bool Enabled { get; set; }

    /// <summary>Root folder; relative paths resolve against the app's content root. One sub-folder per price source code.</summary>
    public string Path { get; set; } = "ingestion-drop";

    /// <summary>How often the folder is scanned.</summary>
    public int PollIntervalSeconds { get; set; } = 10;

    /// <summary>A file is imported only once it has not changed for this long, so a copy still in progress is never read half-written.</summary>
    public int StableSeconds { get; set; } = 5;

    /// <summary>Admin recorded as the uploader on the resulting jobs (an upload job must name who started it). Required when enabled.</summary>
    public Guid UploadAsUserId { get; set; }

    /// <summary>Larger files are moved to <c>failed</c> unread (matches the admin upload limit).</summary>
    public long MaxFileBytes { get; set; } = 10 * 1024 * 1024;
}
