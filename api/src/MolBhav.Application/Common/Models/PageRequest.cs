namespace MolBhav.Application.Common.Models;

/// <summary>1-based paging input, clamped server-side so clients cannot request unbounded pages.</summary>
public sealed record PageRequest
{
    public const int DefaultPageSize = 20;
    public const int MaxPageSize = 100;

    public PageRequest(int page = 1, int pageSize = DefaultPageSize)
    {
        Page = Math.Max(1, page);
        PageSize = Math.Clamp(pageSize, 1, MaxPageSize);
    }

    public int Page { get; }

    public int PageSize { get; }

    public int Offset => (Page - 1) * PageSize;
}
