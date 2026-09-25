using MolBhav.Application.Common.Models;

namespace MolBhav.Api.Contracts;

/// <summary>
/// Success envelope for every 2xx body. Errors are never wrapped: they are RFC 7807 <c>application/problem+json</c>
/// (with <c>errorCode</c> and <c>traceId</c> extensions), so clients branch on HTTP status, not on a flag.
/// </summary>
public sealed record ApiResponse<T>(bool Success, T Data, string? Message = null, PaginationMeta? Pagination = null);

public sealed record PaginationMeta(int Page, int PageSize, long TotalCount, int TotalPages, bool HasNextPage);

public static class ApiResponse
{
    public static ApiResponse<T> Ok<T>(T data, string? message = null) => new(true, data, message);

    public static ApiResponse<IReadOnlyList<T>> Paged<T>(PagedResult<T> page, string? message = null)
    {
        ArgumentNullException.ThrowIfNull(page);

        return new ApiResponse<IReadOnlyList<T>>(
            true,
            page.Items,
            message,
            new PaginationMeta(page.Page, page.PageSize, page.TotalCount, page.TotalPages, page.HasNextPage));
    }
}
